import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';

class Ingreso {
  final String id;
  final String pedidoId;
  final String restauranteId;
  final String? clienteId;
  final double monto;
  final DateTime fecha;
  final List<OrderItem> items;
  final String? notas;
  final int numeroPedido;
  final String? metodoPago;

  Ingreso({
    required this.id,
    required this.pedidoId,
    required this.restauranteId,
    this.clienteId,
    required this.monto,
    required this.fecha,
    required this.items,
    this.notas,
    required this.numeroPedido,
    this.metodoPago = 'Efectivo',
  });

  // Crear un Ingreso a partir de un Pedido
  factory Ingreso.desdePedido(ClientOrder pedido, {String? metodoPago}) {
    return Ingreso(
      id: '', // Se asignará al guardar en Firestore
      pedidoId: pedido.id,
      restauranteId: pedido.restaurantId,
      clienteId: pedido.userId,
      monto: pedido.total,
      fecha: pedido.createdAt,
      items: List<OrderItem>.from(pedido.items),
      notas: pedido.notes,
      numeroPedido: pedido.orderNumber ?? 1,
      metodoPago: metodoPago,
    );
  }

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'pedidoId': pedidoId,
      'restauranteId': restauranteId,
      'clienteId': clienteId,
      'monto': monto,
      'fecha': Timestamp.fromDate(fecha),
      'items': items.map((item) => item.toJson()).toList(),
      'notas': notas,
      'numeroPedido': numeroPedido,
      'metodoPago': metodoPago,
    };
  }

  // Crear desde un documento de Firestore
  factory Ingreso.desdeJson(Map<String, dynamic> json, String id) {
    return Ingreso(
      id: id,
      pedidoId: json['pedidoId'] as String,
      restauranteId: json['restauranteId'] as String,
      clienteId: json['clienteId'] as String?,
      monto: (json['monto'] as num).toDouble(),
      fecha: (json['fecha'] as Timestamp).toDate(),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      notas: json['notas'] as String?,
      numeroPedido: json['numeroPedido'] as int? ?? 1,
      metodoPago: json['metodoPago'] as String? ?? 'Efectivo',
    );
  }

  // Método para actualizar datos
  Ingreso copyWith({
    String? id,
    String? pedidoId,
    String? restauranteId,
    String? clienteId,
    double? monto,
    DateTime? fecha,
    List<OrderItem>? items,
    String? notas,
    int? numeroPedido,
    String? metodoPago,
  }) {
    return Ingreso(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      restauranteId: restauranteId ?? this.restauranteId,
      clienteId: clienteId ?? this.clienteId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      items: items ?? this.items,
      notas: notas ?? this.notas,
      numeroPedido: numeroPedido ?? this.numeroPedido,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }
}
