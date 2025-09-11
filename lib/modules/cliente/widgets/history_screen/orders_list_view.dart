import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'order_card.dart';

class OrdersListView extends StatelessWidget {
  final List<ClientOrder> orders;
  const OrdersListView({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => OrderCard(order: orders[i]),
    );
  }
}
