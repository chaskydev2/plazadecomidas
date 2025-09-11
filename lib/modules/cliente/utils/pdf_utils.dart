import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'order_status_utils.dart';

class PdfUtils {
  static Future<void> generateOrderPdf(ClientOrder order) async {
    final pdf = pw.Document();
    final status = OrderStatusUtils.getStatusText(order.status);

    // For receipt format, use a narrow custom page size (e.g., 80mm width, dynamic height)
    // Use PdfPageFormat.roll80 for typical receipt printers (80mm width, dynamic height)
    final receiptFormat = PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  order.restaurantName ?? 'Restaurante',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (order.restaurantAddress != null &&
                  order.restaurantAddress!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    order.restaurantAddress!,
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (order.sucursalName != null && order.sucursalName!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Sucursal: ${order.sucursalName!}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (order.sucursalAddress != null &&
                  order.sucursalAddress!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    order.sucursalAddress!,
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Pedido #${order.orderNumber}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Text('Estado: $status', style: pw.TextStyle(fontSize: 10)),
              if (order.notes != null && order.notes!.isNotEmpty)
                pw.Text(
                  'Mesa: ${order.notes}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Productos:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.SizedBox(height: 4),
              ...order.items.map(
                (item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item.quantity} x ${item.name}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      'Bs. ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'Bs. ${order.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // Simulate QR code with a placeholder box
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey, width: 1),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'QR',
                          style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColors.grey,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Escanea para ver tu pedido',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  '¡Gracias por tu compra!',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
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
}
