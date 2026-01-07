import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/payment_qr.dart';
import '../../models/payment_receipt.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Subir una imagen a la API externa
  /// [file] es la imagen (File), [folder] es la carpeta destino en el backend
  Future<String> _uploadImageToApi(File imageFile, String folder) async {
    final uri = Uri.parse(
      'https://apiplazacomida.chaskydev.com/api/v1/images/save',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['folder'] = folder;

    if (kIsWeb) {
      // En Web, enviamos bytes
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
    } else {
      // En móvil/escritorio usamos el path del archivo
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map &&
          data['url'] != null &&
          data['url'].toString().isNotEmpty) {
        return data['url'];
      }
      throw Exception('Respuesta JSON sin URL válida: ${response.body}');
    } else {
      throw Exception(
        'Error al subir imagen al API: ${response.statusCode} ${response.body}',
      );
    }
  }

  // =================== QR DE PAGO ===================

  /// Obtener el QR de pago de un restaurante
  Future<PaymentQR?> getRestaurantPaymentQR(String restaurantId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('payment_qrs')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return PaymentQR.fromJson(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error al obtener QR de pago: $e');
      return null;
    }
  }

  /// Crear o actualizar el QR de pago de un restaurante
  Future<PaymentQR> savePaymentQR({
    required String restaurantId,
    required File qrImageFile,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required String accountType,
    String? existingQRId,
  }) async {
    try {
      // 1. Subir la imagen a la API
      final qrImageUrl = await _uploadImageToApi(
        qrImageFile,
        'payment_qrs/$restaurantId',
      );

      // 2. Preparar los datos
      final now = DateTime.now();
      final qrData = PaymentQR(
        id: existingQRId ?? '',
        restaurantId: restaurantId,
        qrImageUrl: qrImageUrl,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        accountType: accountType,
        createdAt: existingQRId != null ? now : now,
        updatedAt: now,
        isActive: true,
      );
      // 3. Guardar en Firestore
      if (existingQRId != null) {
        // Actualizar existente
        await _firestore
            .collection('payment_qrs')
            .doc(existingQRId)
            .update(qrData.toJson());
        return qrData.copyWith(id: existingQRId);
      } else {
        // Crear nuevo
        final docRef = await _firestore
            .collection('payment_qrs')
            .add(qrData.toJson());
        return qrData.copyWith(id: docRef.id);
      }
    } catch (e) {
      print('Error al guardar QR de pago: $e');
      rethrow;
    }
  }

  /// Desactivar el QR de pago actual
  Future<void> deactivatePaymentQR(String qrId) async {
    try {
      await _firestore.collection('payment_qrs').doc(qrId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error al desactivar QR de pago: $e');
      rethrow;
    }
  }

  // =================== COMPROBANTES DE PAGO ===================

  /// Subir un comprobante de pago
  Future<PaymentReceipt> submitPaymentReceipt({
    required String orderId,
    required String restaurantId,
    required String userId,
    required String userName,
    required double amount,
    required File receiptImageFile,
    String? notes,
  }) async {
    try {
      // 1. Subir la imagen del comprobante a la API
      final receiptImageUrl = await _uploadImageToApi(
        receiptImageFile,
        'payment_receipts/$restaurantId',
      );

      // 2. Crear el comprobante
      final receipt = PaymentReceipt(
        id: '',
        orderId: orderId,
        restaurantId: restaurantId,
        userId: userId,
        userName: userName,
        amount: amount,
        receiptImageUrl: receiptImageUrl,
        status: ReceiptStatus.pending,
        submittedAt: DateTime.now(),
        notes: notes,
      );

      // 3. Guardar en Firestore
      final docRef = await _firestore
          .collection('payment_receipts')
          .add(receipt.toJson());

      return receipt.copyWith(id: docRef.id);
    } catch (e) {
      print('Error al subir comprobante de pago: $e');
      rethrow;
    }
  }

  /// Obtener comprobantes pendientes de un restaurante
  Stream<List<PaymentReceipt>> getRestaurantReceipts({
    required String restaurantId,
    ReceiptStatus? status,
  }) {
    Query query = _firestore
        .collection('payment_receipts')
        .where('restaurantId', isEqualTo: restaurantId);

    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status.toString().split('.').last,
      );
    }

    return query.snapshots().map((snapshot) {
      // Ordenar en la app en lugar de en Firestore para evitar necesitar índice compuesto
      final receipts =
          snapshot.docs
              .map(
                (doc) => PaymentReceipt.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Ordenar por fecha de envío, más recientes primero
      receipts.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      return receipts;
    });
  }

  /// Aprobar un comprobante de pago
  Future<void> approveReceipt(String receiptId, String reviewerId) async {
    try {
      await _firestore.collection('payment_receipts').doc(receiptId).update({
        'status': ReceiptStatus.approved.toString().split('.').last,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewerId,
      });
    } catch (e) {
      print('Error al aprobar comprobante: $e');
      rethrow;
    }
  }

  /// Rechazar un comprobante de pago
  Future<void> rejectReceipt(
    String receiptId,
    String reviewerId,
    String rejectionReason,
  ) async {
    try {
      await _firestore.collection('payment_receipts').doc(receiptId).update({
        'status': ReceiptStatus.rejected.toString().split('.').last,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewerId,
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      print('Error al rechazar comprobante: $e');
      rethrow;
    }
  }

  /// Obtener un comprobante específico por ID de orden
  Future<PaymentReceipt?> getReceiptByOrderId(String orderId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('payment_receipts')
              .where('orderId', isEqualTo: orderId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return PaymentReceipt.fromJson(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('Error al obtener comprobante: $e');
      return null;
    }
  }
}
