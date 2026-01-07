import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, confirmed, inProgress, ready, delivered, cancelled }

enum PaymentMethod { cash, qr }

enum PaymentStatus { pending, paid, verified }

class ClientOrder {
  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String? notes;
  final int orderNumber;
  final String? idSucursal;
  final String? restaurantName; // 👈 nuevo
  final String? restaurantAddress; // 👈 nuevo
  final String? sucursalName;
  final String? sucursalAddress;
  final PaymentMethod paymentMethod; // Método de pago
  final PaymentStatus paymentStatus; // Estado del pago
  final String? receiptId; // ID del comprobante de pago (si es por QR)

  ClientOrder({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.notes,
    required this.orderNumber,
    this.idSucursal,
    this.restaurantName,
    this.restaurantAddress,
    this.sucursalName,
    this.sucursalAddress,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.receiptId,
  });

  // Obtener el número de orden formateado con ceros a la izquierda
  String get formattedOrderNumber {
    return orderNumber.toString().padLeft(3, '0');
  }

  factory ClientOrder.fromJson(Map<String, dynamic> json) {
    return ClientOrder(
      id: json['id'] as String,
      restaurantId: (json['restaurantId'] ?? '') as String,
      userId: (json['userId'] ?? 'anonymous') as String,
      userName: (json['userName'] ?? 'Guest User') as String,
      items:
          (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList(),
      total: (json['total'] != null ? (json['total'] as num).toDouble() : 0.0),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      notes: json['notes'] as String?,
      orderNumber: (json['orderNumber'] as int?) ?? 1,
      idSucursal: json['idSucursal'] as String?,
      restaurantName: json['restaurantName'], // 👈
      restaurantAddress: json['restaurantAddress'], // 👈
      sucursalName: json['sucursalName'] as String?,
      sucursalAddress: json['sucursalAddress'] as String?,
      paymentMethod:
          json['paymentMethod'] != null
              ? PaymentMethod.values.firstWhere(
                (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
                orElse: () => PaymentMethod.cash,
              )
              : PaymentMethod.cash,
      paymentStatus:
          json['paymentStatus'] != null
              ? PaymentStatus.values.firstWhere(
                (e) => e.toString() == 'PaymentStatus.${json['paymentStatus']}',
                orElse: () => PaymentStatus.pending,
              )
              : PaymentStatus.pending,
      receiptId: json['receiptId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'userId': userId,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'userName': userName,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'orderNumber': orderNumber,
      'idSucursal': idSucursal,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'receiptId': receiptId,
    };
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    };
  }
}
