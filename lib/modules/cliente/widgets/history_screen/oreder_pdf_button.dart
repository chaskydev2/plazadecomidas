import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:kokorestaurant/modules/cliente/utils/pdf_utils.dart';

class OrderPdfButton extends StatelessWidget {
  final ClientOrder? order; // opcional si recibes por prop
  const OrderPdfButton({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final o = order ?? _OrderProvider.of(context); // permite ambas modalidades
    return ElevatedButton(
      onPressed: () => PdfUtils.generateOrderPdf(o),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF7043),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Descargar PDF'),
    );
  }
}

/// Pequeño provider local opcional para no pasar 'order' por todos los niveles.
/// Úsalo así: wrappea la sección con _OrderProvider(order: order, child: OrderPdfButton())
class _OrderProvider extends InheritedWidget {
  final ClientOrder order;
  const _OrderProvider({required this.order, required super.child, super.key});

  static ClientOrder of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_OrderProvider>();
    assert(result != null, 'No _OrderProvider found in context');
    return result!.order;
  }

  @override
  bool updateShouldNotify(_OrderProvider oldWidget) => order != oldWidget.order;
}
