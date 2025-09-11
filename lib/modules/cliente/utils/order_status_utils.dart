import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';

class OrderStatusUtils {
  static String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.inProgress:
      case OrderStatus.ready:
        return 'Progreso';
      case OrderStatus.delivered:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF9CDAE);
      case OrderStatus.confirmed:
        return const Color(0xFFCCE5FF);
      case OrderStatus.inProgress:
      case OrderStatus.ready:
        return const Color(0xFFB7DFF3);
      case OrderStatus.delivered:
        return const Color(0xFFB6E3C5);
      case OrderStatus.cancelled:
        return Colors.red[600]!;
    }
  }
}
