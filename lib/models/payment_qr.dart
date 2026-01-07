import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para el QR de pago del restaurante
class PaymentQR {
  final String id;
  final String restaurantId;
  final String qrImageUrl; // URL de la imagen del QR en Firebase Storage
  final String bankName; // Nombre del banco
  final String accountNumber; // Número de cuenta
  final String accountHolder; // Titular de la cuenta
  final String accountType; // Tipo de cuenta (Ahorro, Corriente, etc.)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PaymentQR({
    required this.id,
    required this.restaurantId,
    required this.qrImageUrl,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.accountType,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory PaymentQR.fromJson(Map<String, dynamic> json, String id) {
    return PaymentQR(
      id: id,
      restaurantId: json['restaurantId'] as String,
      qrImageUrl: json['qrImageUrl'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountHolder: json['accountHolder'] as String,
      accountType: json['accountType'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'qrImageUrl': qrImageUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'accountType': accountType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  PaymentQR copyWith({
    String? id,
    String? restaurantId,
    String? qrImageUrl,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? accountType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PaymentQR(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
