import 'package:flutter/material.dart';

class OrderItemRow extends StatelessWidget {
  final int quantity;
  final String name;
  final double price;

  const OrderItemRow({
    super.key,
    required this.quantity,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final total = (quantity * price).toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${quantity}x $name',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Text(
            'Bs. $total',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
