import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados del comprobante de pago
enum ReceiptStatus {
  pending, // Pendiente de aprobación
  approved, // Aprobado por el restaurante
  rejected, // Rechazado por el restaurante
}

/// Modelo para el comprobante de pago del cliente
class PaymentReceipt {
  final String id;
  final String orderId; // ID del pedido asociado
  final String restaurantId; // ID del restaurante
  final String userId; // ID del cliente que hizo el pago
  final String userName; // Nombre del cliente
  final double amount; // Monto pagado
  final String receiptImageUrl; // URL de la imagen del comprobante
  final ReceiptStatus status; // Estado del comprobante
  final DateTime submittedAt; // Fecha de envío del comprobante
  final DateTime? reviewedAt; // Fecha de revisión (aprobación/rechazo)
  final String? reviewedBy; // ID del manager que revisó
  final String? rejectionReason; // Motivo de rechazo (si aplica)
  final String? notes; // Notas adicionales

  PaymentReceipt({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.receiptImageUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  });

  factory PaymentReceipt.fromJson(Map<String, dynamic> json, String id) {
    return PaymentReceipt(
      id: id,
      orderId: json['orderId'] as String,
      restaurantId: json['restaurantId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      amount: (json['amount'] as num).toDouble(),
      receiptImageUrl: json['receiptImageUrl'] as String,
      status: ReceiptStatus.values.firstWhere(
        (e) => e.toString() == 'ReceiptStatus.${json['status']}',
        orElse: () => ReceiptStatus.pending,
      ),
      submittedAt: (json['submittedAt'] as Timestamp).toDate(),
      reviewedAt:
          json['reviewedAt'] != null
              ? (json['reviewedAt'] as Timestamp).toDate()
              : null,
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'receiptImageUrl': receiptImageUrl,
      'status': status.toString().split('.').last,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
    };
  }

  PaymentReceipt copyWith({
    String? id,
    String? orderId,
    String? restaurantId,
    String? userId,
    String? userName,
    double? amount,
    String? receiptImageUrl,
    ReceiptStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
  }) {
    return PaymentReceipt(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }

  /// Obtiene el color según el estado
  static int getStatusColor(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.pending:
        return 0xFFFFA726; // Naranja
      case ReceiptStatus.approved:
        return 0xFF66BB6A; // Verde
      case ReceiptStatus.rejected:
        return 0xFFEF5350; // Rojo
    }
  }

  /// Obtiene el texto del estado en español
  static String getStatusText(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.pending:
        return 'Pendiente';
      case ReceiptStatus.approved:
        return 'Aprobado';
      case ReceiptStatus.rejected:
        return 'Rechazado';
    }
  }
}
