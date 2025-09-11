import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:kokorestaurant/modules/manager/models/ingreso.dart';
import 'package:kokorestaurant/modules/manager/services/ingreso_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class _OrderCardContent extends StatefulWidget {
  final ClientOrder order;
  final BuildContext parentContext;

  const _OrderCardContent({required this.order, required this.parentContext});

  @override
  _OrderCardContentState createState() => _OrderCardContentState();
}

class _OrderCardContentState extends State<_OrderCardContent> {
  // Estado para controlar si se muestran todos los ítems
  bool _showAllItems = false;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        {
          OrderStatus.pending: Colors.orange,
          OrderStatus.confirmed: Colors.blue,
          OrderStatus.inProgress: Colors.purple,
          OrderStatus.ready: Colors.green,
          OrderStatus.delivered: Colors.green[800],
          OrderStatus.cancelled: Colors.red,
        }[widget.order.status] ??
        Colors.grey;

    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    final formattedDate = dateFormat.format(widget.order.createdAt);
    final formattedOrderNumber = widget.order.orderNumber.toString().padLeft(
      3,
      '0',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Orden #$formattedOrderNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getStatusText(widget.order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (widget.order.userName.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.order.userName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mostrar número de mesa si está disponible en las notas
                if (widget.order.notes != null &&
                    widget.order.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mesa: ${widget.order.notes!.replaceAll('mesa', '').replaceAll('Mesa', '').trim()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ...(_showAllItems
                        ? widget.order.items
                        : widget.order.items.take(2))
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.name}',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Bs. ${(item.quantity * item.price).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (widget.order.items.length > 2) ...{
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllItems = !_showAllItems;
                      });
                    },
                    child: Text(
                      _showAllItems
                          ? 'Mostrar menos'
                          : '+${widget.order.items.length - 2} ítems más...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                },
                const Divider(height: 24, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bs. ${widget.order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD91010),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.order.status == OrderStatus.ready ||
                    widget.order.status == OrderStatus.delivered)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _mostrarRecibo(widget.order, context),
                      icon: const Icon(Icons.receipt, size: 18),
                      label: const Text('Ver Recibo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: Colors.blue[700]!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.order.status != OrderStatus.delivered &&
              widget.order.status != OrderStatus.cancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildOrderButtons(
                  widget.order,
                  widget.parentContext,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.inProgress:
        return 'En Progreso';
      case OrderStatus.ready:
        return 'Listo';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  List<Widget> _buildOrderButtons(ClientOrder order, BuildContext context) {
    return [];
  }

  Future<void> _generarYCompartirPDF(
    ClientOrder order,
    String restaurantName,
    String restaurantAddress,
  ) async {
    try {
      // Crear el documento PDF
      final pdf = pw.Document();

      // Agregar una página al PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            80.0 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado del restaurante
                pw.Text(
                  restaurantName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  restaurantAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'RECIBO DE PAGO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'N°: ${order.orderNumber.toString().padLeft(6, '0')}',
                    ),
                    pw.Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Cliente: ${order.userName}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Divider(thickness: 0.5),
                pw.Text(
                  'DETALLE:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                // Lista de ítems
                ...order.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '${item.quantity}x ${item.name}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          '${(item.quantity * item.price).toStringAsFixed(2)} Bs',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL PAGADO:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${order.total.toStringAsFixed(2)} Bs',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Forma de pago: QR',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '¡Gracias por su compra!',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF en un archivo temporal
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/recibo_${order.orderNumber}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Recibo de compra #${order.orderNumber}',
        subject: 'Recibo de compra',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarRecibo(ClientOrder order, BuildContext context) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormat.format(order.createdAt);
    final formattedOrderNumber = order.orderNumber.toString().padLeft(6, '0');

    try {
      final restaurantDoc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(order.restaurantId)
              .get();

      final restaurantData = restaurantDoc.data() ?? {};
      final restaurantName =
          restaurantData['name']?.toString() ?? 'POLLOS RÁPIDOS';
      final restaurantAddress =
          restaurantData['location']?.toString() ?? 'Av. Libertador #1234';

      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurantAddress,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'RECIBO DE PAGO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('N°: $formattedOrderNumber'),
                          Text('Fecha: $formattedDate'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cliente: ${order.userName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detalle:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('${item.quantity} x ${item.name}'),
                              ),
                              Text(
                                '${(item.quantity * item.price).toStringAsFixed(2)} Bs',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(thickness: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL PAGADO:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${order.total.toStringAsFixed(2)} Bs',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Forma de pago: QR',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar el diálogo
                          _generarYCompartirPDF(
                            order,
                            restaurantName,
                            restaurantAddress,
                          );
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Imprimir Recibo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¡Gracias por su compra!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
