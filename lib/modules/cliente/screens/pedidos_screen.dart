// lib/modules/cliente/screens/pedidos/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/modules/cliente/widgets/pedidos_screen/bottom_summary_bar.dart';
import 'package:kokorestaurant/modules/cliente/widgets/pedidos_screen/cart_empty.dart';
import 'package:kokorestaurant/modules/cliente/widgets/pedidos_screen/cart_item_tile.dart';
import 'package:kokorestaurant/modules/cliente/widgets/pedidos_screen/cart_summary_card.dart';
import 'package:kokorestaurant/modules/cliente/widgets/pedidos_screen/sucess_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../services/qr_service.dart';
import '../services/history_service.dart';
import 'qr_payment_screen.dart';

class PedidosScreen extends StatefulWidget {
  final List<MenuItem> pedidos;
  final Function(List<MenuItem>) onUpdate;
  final String qrCode;
  final String restaurantId;
  final String userId;
  final Restaurant restaurant;

  const PedidosScreen({
    super.key,
    required this.pedidos,
    required this.onUpdate,
    required this.qrCode,
    required this.restaurantId,
    required this.userId,
    required this.restaurant,
  });

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen>
    with SingleTickerProviderStateMixin {
  List<MenuItem> _pedidos = [];
  bool _isSending = false;
  String idSucursal = '';
  String userNameOrder = '';
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash; // Nuevo

  @override
  void initState() {
    super.initState();
    _pedidos = List.from(widget.pedidos);
  }

  void _eliminarPedido(MenuItem item) {
    setState(() => _pedidos.remove(item));
    widget.onUpdate(_pedidos);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: Theme.of(context).primaryColor,
        content: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Producto eliminado: ${item.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateCantidad(int index, int delta) {
    final item = _pedidos[index];
    final newQty = (item.quantity + delta).clamp(1, 999);
    setState(() => _pedidos[index] = item.copyWith(quantity: newQty));
    widget.onUpdate(_pedidos);
  }

  double _calcularSubtotal() =>
      _pedidos.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double _calcularTotal() =>
      _calcularSubtotal(); // si luego hay delivery/desc., ajusta aquí

  Future<void> _enviarPedido() async {
    if (_isSending) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (_) => _PaymentMethodDialog(currentMethod: _selectedPaymentMethod),
    );

    if (result == null || result['confirmed'] != true) return;

    // Actualizar el método de pago seleccionado
    setState(() => _selectedPaymentMethod = result['paymentMethod']);

    // Si el método de pago es QR, mostrar la pantalla de pago QR
    if (_selectedPaymentMethod == PaymentMethod.qr) {
      // Navegar a la pantalla de pago por QR
      final qrPaymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => QRPaymentScreen(
                restaurantId: widget.restaurantId,
                amount: _calcularTotal(),
                restaurantName: widget.restaurant.name,
              ),
        ),
      );

      if (qrPaymentResult == null || qrPaymentResult['paid'] != true) {
        // Usuario canceló el pago por QR
        return;
      }

      // Usuario completó el pago por QR, crear orden con el receiptId
      await _createOrderWithPayment(
        paymentMethod: PaymentMethod.qr,
        receiptId: qrPaymentResult['receiptId'],
      );
    } else {
      // Flujo normal con efectivo
      await _createOrderWithPayment(paymentMethod: PaymentMethod.cash);
    }
  }

  Future<void> _createOrderWithPayment({
    required PaymentMethod paymentMethod,
    String? receiptId,
  }) async {
    setState(() => _isSending = true);
    try {
      if (widget.qrCode.isEmpty) {
        await _createOrderWithoutQr(
          paymentMethod: paymentMethod,
          receiptId: receiptId,
        );
      } else {
        await _createOrderWithQr(
          paymentMethod: paymentMethod,
          receiptId: receiptId,
        );
      }

      widget.onUpdate([]);
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => SuccessDialog(
              onPrimary: () async {
                Navigator.pop(context);
                await _generarPDFyDescargar(context);
                Navigator.pop(context);
              },
            ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _createOrderWithQr({
    required PaymentMethod paymentMethod,
    String? receiptId,
  }) async {
    final table = await QRService().validateQR(widget.qrCode);
    if (table == null) {
      throw Exception(
        'No se pudo validar la mesa. Por favor, escanee el código QR nuevamente.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    String userName = 'Invitado';

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        userName = userDoc.data()!['name'] as String;
      }
    }

    userNameOrder = userName;
    final orderNumber = await QRService().getNextOrderNumber(
      table.restaurantId,
    );
    final orderId = await QRService().createOrderForTable(
      table.id,
      table.restaurantId,
      userName: userName,
    );

    final orderRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(table.restaurantId)
        .collection('orders')
        .doc(orderId);

    final order = ClientOrder(
      id: orderRef.id,
      restaurantId: table.restaurantId,
      userId: user?.uid ?? 'mesa-${table.number}',
      userName: userName,
      items:
          _pedidos
              .map(
                (i) => OrderItem(
                  id: i.id,
                  name: i.name,
                  quantity: i.quantity,
                  price: i.price,
                ),
              )
              .toList(),
      total: _calcularTotal(),
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      notes: 'Mesa ${table.number}',
      orderNumber: orderNumber,
      paymentMethod: paymentMethod,
      paymentStatus:
          paymentMethod == PaymentMethod.qr
              ? PaymentStatus.pending
              : PaymentStatus.pending,
      receiptId: receiptId,
    );

    await orderRef.set(order.toJson());

    if (user != null) {
      try {
        await HistoryService().addToOrderHistory(user.uid, order);
      } catch (_) {}
    }

    final formatted = orderNumber.toString().padLeft(3, '0');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #$formatted enviado correctamente'),
          backgroundColor: const Color(0xFFD91010),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _createOrderWithoutQr({
    required PaymentMethod paymentMethod,
    String? receiptId,
  }) async {
    final table = await QRService().sendOrder(
      widget.restaurantId,
      FirebaseAuth.instance.currentUser?.displayName ?? 'Invitado',
    );

    final user = FirebaseAuth.instance.currentUser;
    String userName = 'Invitado';

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        userName = userDoc.data()!['name'] as String;
      }
    }

    final orderNumber = await QRService().getNextOrderNumber(
      widget.restaurantId,
    );
    final orderId = await QRService().createOrderForSend(
      widget.restaurantId,
      userName: userName,
    );

    final orderRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('orders')
        .doc(orderId);

    final order = ClientOrder(
      id: orderRef.id,
      restaurantId: widget.restaurantId,
      userId: user?.uid ?? 'para llevar',
      userName: userName,
      items:
          _pedidos
              .map(
                (i) => OrderItem(
                  id: i.id,
                  name: i.name,
                  quantity: i.quantity,
                  price: i.price,
                ),
              )
              .toList(),
      total: _calcularTotal(),
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      notes: 'Pedido para llevar',
      orderNumber: orderNumber,
      // Nuevo campo para la sucursal
      idSucursal: idSucursal,
      paymentMethod: paymentMethod,
      paymentStatus:
          paymentMethod == PaymentMethod.qr
              ? PaymentStatus.pending
              : PaymentStatus.pending,
      receiptId: receiptId,
    );

    await orderRef.set(order.toJson());

    if (user != null) {
      try {
        await HistoryService().addToOrderHistory(user.uid, order);
      } catch (_) {}
    }

    final formatted = orderNumber.toString().padLeft(3, '0');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #$formatted enviado correctamente'),
          backgroundColor: const Color(0xFFD91010),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // opcional log
    // ignore: avoid_print
    print('Pedido enviado sin QR: ${table?.id ?? 'No se pudo enviar'}');
  }

  Future<void> _generarPDFyDescargar(BuildContext context) async {
    final pdf = pw.Document();
    // Buscar sucursal seleccionada si existe
    String? sucursalNombre;
    String? sucursalDireccion;
    // Si tienes la lista de sucursales cargada, puedes buscarla aquí
    // Por ejemplo, si tienes una variable branches:
    // final branch = branches.firstWhere((b) => b['id'] == idSucursal, orElse: () => null);
    // if (branch != null) {
    //   sucursalNombre = branch['nombre'];
    //   sucursalDireccion = branch['direccion'];
    // }
    // Por ahora, solo mostramos la dirección general si no hay sucursal
    final direccionMostrar = sucursalDireccion ?? widget.restaurant.location;
    final nombreSucursalMostrar = sucursalNombre;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4,
        ),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('🎟️', style: pw.TextStyle(fontSize: 22)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'KOKO RESTAURANT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.Text(
                'Fecha: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Usuario: ${userNameOrder}',
                style: pw.TextStyle(fontSize: 8),
              ),
              if (nombreSucursalMostrar != null &&
                  nombreSucursalMostrar.isNotEmpty)
                pw.Text(
                  'Sucursal: $nombreSucursalMostrar',
                  style: pw.TextStyle(fontSize: 8),
                ),
              pw.Text(
                'Dirección: $direccionMostrar',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Restaurante: ${widget.restaurant.name}',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.Text(
                'DETALLES',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              ..._pedidos.map(
                (item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item.name}${item.quantity > 1 ? ' x${item.quantity}' : ''}',
                        style: pw.TextStyle(fontSize: 8),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                    pw.Text(
                      '${(item.price * item.quantity).toStringAsFixed(2)} Bs',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_calcularTotal().toStringAsFixed(2)} Bs',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '¡Gracias por tu compra!',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calcularSubtotal();
    final total = _calcularTotal();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Tu Pedido',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            _pedidos.isEmpty
                                ? const CartEmpty()
                                : ListView.separated(
                                  itemCount: _pedidos.length,
                                  padding: const EdgeInsets.all(12),
                                  separatorBuilder:
                                      (_, __) => const Divider(
                                        height: 20,
                                        thickness: 0.5,
                                        color: Color(0xFFFDEAE8),
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = _pedidos[index];
                                    return CartItemTile(
                                      item: item,
                                      onDecrease:
                                          item.quantity > 1
                                              ? () => _updateCantidad(index, -1)
                                              : null,
                                      onIncrease:
                                          () => _updateCantidad(index, 1),
                                      onDelete: () => _eliminarPedido(item),
                                    );
                                  },
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: CartSummaryCard(subtotal: subtotal),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 160),
            ],
          ),
          BottomSummaryBar(
            address: widget.restaurant.location,
            total: total,
            isSending: _isSending,
            isDisabled: _pedidos.isEmpty,
            idRestaurant: widget.restaurantId,
            onSend: _enviarPedido,
            onBranchChanged: (String? branchId) {
              setState(() {
                idSucursal = branchId ?? '';
              });
            },
          ),
        ],
      ),
    );
  }
}

// --- Dialogo de confirmación rápido (siguiendo tu estilo) ---
class _ConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Icon(Icons.restaurant_menu, color: Color(0xFFFF6243)),
          SizedBox(width: 8),
          Text(
            'Confirmar Pedido',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        '¿Estás seguro de enviar el pedido?',
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6243),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Enviar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// --- Diálogo de selección de método de pago ---
class _PaymentMethodDialog extends StatefulWidget {
  final PaymentMethod currentMethod;

  const _PaymentMethodDialog({required this.currentMethod});

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  late PaymentMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Icon(Icons.payment, color: Color(0xFFFF6243)),
          SizedBox(width: 8),
          Text(
            'Método de Pago',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona cómo deseas pagar tu pedido:',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          _PaymentMethodOption(
            icon: Icons.money,
            title: 'Efectivo',
            subtitle: 'Paga al recibir tu pedido',
            isSelected: _selectedMethod == PaymentMethod.cash,
            onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
          ),
          const SizedBox(height: 12),
          _PaymentMethodOption(
            icon: Icons.qr_code,
            title: 'Pago por QR',
            subtitle: 'Paga con transferencia bancaria',
            isSelected: _selectedMethod == PaymentMethod.qr,
            onTap: () => setState(() => _selectedMethod = PaymentMethod.qr),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              () => Navigator.pop(context, {
                'confirmed': true,
                'paymentMethod': _selectedMethod,
              }),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6243),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Continuar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6243) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected
                  ? const Color(0xFFFF6243).withOpacity(0.05)
                  : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6243) : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFFFF6243) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF6243),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
