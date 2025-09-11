// lib/modules/cliente/screens/pedidos/widgets/cart_item_tile.dart
import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/menu_item.dart';

class CartItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity;
    final totalItem = item.price * quantity;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEAE8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    item.imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.imageUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.restaurant_menu,
                                  color: Color(0xFFFF6243),
                                  size: 28,
                                ),
                          ),
                        )
                        : const Icon(
                          Icons.restaurant_menu,
                          color: Color(0xFFFF6243),
                          size: 28,
                        ),
              ),
              if (quantity > 1)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6243),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x$quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} Bs. c/u',
                  style: const TextStyle(
                    color: Color(0xFFFF6243),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (quantity > 1)
                  Text(
                    'Total: ${totalItem.toStringAsFixed(2)} Bs',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Disminuir',
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
                color: (quantity > 1) ? Colors.grey[700] : Colors.grey[300],
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar',
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.grey[700],
              ),
            ],
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD91010),
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
