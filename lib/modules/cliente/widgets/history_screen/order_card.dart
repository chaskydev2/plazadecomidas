import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:kokorestaurant/modules/cliente/utils/order_status_utils.dart';
import 'package:kokorestaurant/modules/cliente/widgets/history_screen/oreder_item_row.dart';
import 'package:kokorestaurant/modules/cliente/widgets/history_screen/oreder_pdf_button.dart';

class OrderCard extends StatelessWidget {
  final ClientOrder order;
  final void Function()? onDelete;
  const OrderCard({super.key, required this.order, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy • HH:mm').format(order.createdAt);
    final statusText = OrderStatusUtils.getStatusText(order.status);
    final statusColor = OrderStatusUtils.getStatusColor(order.status);
    final itemsCount = order.items.fold<int>(
      0,
      (acc, it) => acc + (it.quantity),
    );
    final totalText = _money(order.total);

    // Debug print to show what data is in order.items
    // ignore: avoid_print
    print(
      'order.items: ' +
          order.items.map((e) => e.toString()).toList().toString(),
    );

    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.red.shade400,
        child: const Icon(
          Icons.delete_forever_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        // Si el pedido está en progreso o listo, mostrar mensaje personalizado y no permitir eliminar
        if (order.status == OrderStatus.inProgress ||
            order.status == OrderStatus.ready) {
          await showDialog<void>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('No se puede eliminar'),
                  content: const Text(
                    'Este pedido está en progreso o listo para entregar y no puede ser eliminado. Solo puedes eliminar pedidos que no estén en proceso de preparación o listos para entrega.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
          );
          return false;
        }
        // Si no, mostrar confirmación normal
        final result = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Eliminar pedido'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este pedido? Esta acción no se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        );
        return result == true;
      },
      onDismissed: (_) {
        if (onDelete != null) onDelete!();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // franja lateral con degradado
              Positioned.fill(
                left: 0,
                right: null,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFF7043),
                        const Color(0xFFFF7043).withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),
              // contenido
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    collapsedBackgroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    trailing: const Icon(Icons.expand_more_rounded),
                    title: _HeaderRow(
                      restaurantName: order.restaurantName ?? 'Desconocido',
                      restaurantAddress:
                          order.sucursalAddress ??
                          order.restaurantAddress ??
                          'Desconocido',
                      orderNumber: order.orderNumber.toString(),
                      dateText: date,
                      statusText: statusText,
                      statusColor: statusColor,
                      itemsCount: itemsCount,
                    ),

                    children: [
                      const SizedBox(height: 8),
                      const _SectionTitle(text: 'Productos del pedido'),
                      const SizedBox(height: 8),

                      // Debug print to show what data is in order.items
                      // ignore: avoid_print
                      //       print('order.items: ' + order.items.map((e) => e.toString()).toList().toString());

                      // lista de ítems
                      ...order.items.map(
                        (it) => OrderItemRow(
                          quantity: it.quantity,
                          name: it.name,
                          price: it.price,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // notas (mesa) como chip
                      if (order.notes != null && order.notes!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _InfoChip(
                              icon: Icons.event_seat_rounded,
                              label:
                                  'Mesa: ${order.notes!.replaceAll(RegExp(r'[Mm]esa'), '').trim()}',
                            ),
                          ),
                        ),

                      // barra de total + acción
                      _TotalBar(
                        totalText: totalText,
                        action: OrderPdfButton(order: order),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _money(num n) => 'Bs. ${n.toStringAsFixed(2)}';
}

class _HeaderRow extends StatelessWidget {
  final String orderNumber;
  final String dateText;
  final String statusText;
  final Color statusColor;
  final int itemsCount;
  final String? restaurantName;
  final String? restaurantAddress;

  const _HeaderRow({
    required this.orderNumber,
    required this.dateText,
    required this.statusText,
    required this.statusColor,
    required this.itemsCount,
    required this.restaurantName,
    required this.restaurantAddress,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(fontSize: 12.5, color: Colors.grey[700]);
    final infoStyle = TextStyle(fontSize: 12, color: Colors.grey[600]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // icono de pedido
        Container(
          height: 40,
          width: 40,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: const Icon(Icons.receipt_long_rounded, size: 22),
        ),
        // textos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // título + chip estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #$orderNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(text: statusText, color: statusColor),
                ],
              ),
              // Restaurante y dirección
              if (restaurantName != null && restaurantName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                  child: Text(
                    restaurantName!,
                    style: infoStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (restaurantAddress != null && restaurantAddress!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    restaurantAddress!,
                    style: infoStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 6),
              // fecha + cantidad items
              Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(dateText, style: subtitleStyle),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$itemsCount ítem${itemsCount == 1 ? '' : 's'}',
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          height: 1,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15.5,
        color: Color(0xFF444444),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  final String totalText;
  final Widget action;
  const _TotalBar({required this.totalText, required this.action});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    totalText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // botón principal (PDF)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: action,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
