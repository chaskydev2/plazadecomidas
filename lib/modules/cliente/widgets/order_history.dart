import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:kokorestaurant/modules/cliente/services/order_service.dart';

class OrderHistory extends StatelessWidget {
  final String userId;
  final OrderService _orderService = OrderService();

  OrderHistory({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Historial de Pedidos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FutureBuilder<List<ClientOrder>>(
          future: _orderService.getUserOrders(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error al cargar el historial de pedidos'),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return const Center(
                child: Text('No hay pedidos para mostrar'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(order: order);
              },
            );
          },
        ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final ClientOrder order;

  const OrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navegar al detalle del pedido
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFD91010),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${_formatDate(order.createdAt)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmado';
        break;
      case OrderStatus.inProgress:
        color = Colors.purple;
        text = 'En Proceso';
        break;
      case OrderStatus.ready:
        color = Colors.green;
        text = 'Listo';
        break;
      case OrderStatus.delivered:
        color = Colors.teal;
        text = 'Entregado';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 