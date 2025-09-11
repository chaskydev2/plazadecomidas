import 'package:flutter/material.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import '../models/table.dart';
import '../../cliente/services/qr_service.dart';
import '../services/tables_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:printing/printing.dart';

class TablesManagementScreen extends StatefulWidget {
  final String restaurantId;

  const TablesManagementScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  State<TablesManagementScreen> createState() => _TablesManagementScreenState();
}

class _TablesManagementScreenState extends State<TablesManagementScreen> {
  final TablesService _tablesService = TablesService();
  final TextEditingController _tableNumberController = TextEditingController();

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTableDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Mesa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        tooltip: 'Agregar nueva mesa',
      ),
      body: StreamBuilder<List<RestaurantTable>>(
        stream: _tablesService.getTables(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD91010)),
            );
          }

          final tables = snapshot.data!;

          if (tables.isEmpty) {
            return const Center(
              child: Text(
                'No hay mesas registradas',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
                color: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    'Mesa ${table.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    table.isOccupied ? 'Ocupada' : 'Disponible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        onPressed: () => _showQRCodeDialog(table),
                      ),
                      IconButton(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD91010),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Color(0xFFD91010),
                            size: 24,
                          ),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Confirmar eliminación',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mesa ${table.number}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    '¿Está seguro de que desea eliminar la mesa ${table.number}?',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true && mounted) {
                            try {
                              await _tablesService.deleteTable(
                                widget.restaurantId,
                                table.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mesa eliminada exitosamente',
                                    ),
                                    backgroundColor: Color(0xFFD91010),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al eliminar la mesa: $e',
                                    ),
                                    backgroundColor: const Color(0xFFD91010),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        color: Colors.white,
                      ),
                    ],
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD91010),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      table.isOccupied ? Icons.people : Icons.event_seat,
                      color: const Color(0xFFD91010),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddTableDialog() async {
    _tableNumberController.clear();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            title: Row(
              children: [
                const Icon(Icons.table_restaurant, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Agregar nueva mesa',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tableNumberController,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'Número de mesa',
                      labelStyle: const TextStyle(color: AppColors.text),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.event_seat,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.boton),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.montserrat(
                      color: AppColors.boton,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_tableNumberController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingrese un número de mesa'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      return;
                    }

                    final number = int.tryParse(_tableNumberController.text);
                    if (number == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingrese un número válido'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      return;
                    }

                    try {
                      final qrData = {
                        'type': 'table',
                        'restaurantId': widget.restaurantId,
                        'tableNumber': number,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      };

                      final table = RestaurantTable(
                        id: '',
                        number: number,
                        restaurantId: widget.restaurantId,
                        qrCode: jsonEncode(qrData),
                        isOccupied: false,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await _tablesService.addTable(table);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mesa agregada exitosamente'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al agregar mesa: $e'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    'Agregar',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showQRCodeDialog(RestaurantTable table) {
    final qrData = jsonDecode(table.qrCode);
    final GlobalKey qrKey = GlobalKey();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Código QR - Mesa ${table.number}',
              style: const TextStyle(color: Color(0xFFD91010)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          table.isOccupied
                              ? const Color(0xFFD91010)
                              : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: RepaintBoundary(
                    key: qrKey,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data: jsonEncode(qrData),
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Verificar y solicitar permisos
                      if (!await _requestStoragePermission()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor, otorgue los permisos necesarios para guardar el PDF',
                            ),
                            backgroundColor: Color(0xFFD91010),
                          ),
                        );
                        return;
                      }
                      // Capturar el QR como imagen
                      final boundary =
                          qrKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?;
                      if (boundary == null) {
                        throw Exception('No se pudo capturar el QR');
                      }
                      final image = await boundary.toImage();
                      final byteData = await image.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                      if (byteData == null) {
                        throw Exception('No se pudo convertir el QR a imagen');
                      }
                      final qrImage = byteData.buffer.asUint8List();

                      // Generar el PDF
                      final pdf = pw.Document();

                      // Cargar la fuente Helvetica
                      final fontData = await rootBundle.load(
                        'assets/fonts/Helvetica-Bold.ttf',
                      );
                      final ttf = pw.Font.ttf(fontData);

                      pdf.addPage(
                        pw.Page(
                          pageFormat: PdfPageFormat.a4,
                          build: (pw.Context context) {
                            return pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'Mesa ${table.number}',
                                    style: pw.TextStyle(
                                      fontSize: 24,
                                      fontWeight: pw.FontWeight.bold,
                                      font: ttf,
                                    ),
                                  ),
                                  pw.SizedBox(height: 20),
                                  pw.Image(
                                    pw.MemoryImage(qrImage),
                                    width: 300,
                                    height: 300,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );

                      // Generar el PDF en memoria
                      final pdfBytes = await pdf.save();

                      if (mounted) {
                        if (kIsWeb) {
                          // Para web, descargar automáticamente
                          final blob = html.Blob([pdfBytes], 'application/pdf');
                          final url = html.Url.createObjectUrlFromBlob(blob);
                          final anchor =
                              html.AnchorElement(href: url)
                                ..setAttribute(
                                  'download',
                                  'qr_mesa_${table.number}.pdf',
                                )
                                ..click();
                          html.Url.revokeObjectUrl(url);
                        } else {
                          // Para dispositivos móviles
                          // Solicitar permisos de almacenamiento
                          final status = await Permission.storage.request();
                          if (!status.isGranted) {
                            throw Exception(
                              'Se requieren permisos de almacenamiento para guardar el PDF',
                            );
                          }

                          // Obtener el directorio de descargas
                          Directory? directory;
                          if (Platform.isAndroid) {
                            directory = Directory(
                              '/storage/emulated/0/Download',
                            );
                            if (!await directory.exists()) {
                              directory = await getExternalStorageDirectory();
                            }
                          } else {
                            directory = await getDownloadsDirectory();
                          }

                          if (directory == null) {
                            throw Exception(
                              'No se pudo acceder al directorio de descargas',
                            );
                          }

                          // Crear el directorio si no existe
                          if (!await directory.exists()) {
                            await directory.create(recursive: true);
                          }

                          // Guardar el PDF
                          final file = File(
                            '${directory.path}/qr_mesa_${table.number}.pdf',
                          );
                          await file.writeAsBytes(pdfBytes);

                          // Mostrar diálogo de éxito
                          final shareResult = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  backgroundColor: Colors.black,
                                  title: const Text(
                                    'PDF Guardado',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'El PDF se ha guardado exitosamente.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ubicación: ${file.path}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text(
                                        'Cerrar',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFD91010,
                                        ),
                                      ),
                                      child: const Text('Compartir'),
                                    ),
                                  ],
                                ),
                          );

                          if (shareResult == true) {
                            await Share.shareXFiles([
                              XFile.fromData(
                                pdfBytes,
                                name: 'qr_mesa_${table.number}.pdf',
                                mimeType: 'application/pdf',
                              ),
                            ], text: 'Código QR para la mesa ${table.number}');
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF generado exitosamente'),
                            backgroundColor: Color(0xFFD91010),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al generar el PDF: $e'),
                            backgroundColor: const Color(0xFFD91010),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD91010),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar QR'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final boundary =
                          qrKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?;
                      if (boundary == null)
                        throw Exception('No se pudo capturar el QR');
                      final image = await boundary.toImage();
                      final byteData = await image.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                      if (byteData == null)
                        throw Exception('No se pudo convertir el QR a imagen');
                      final qrImage = byteData.buffer.asUint8List();

                      final pdf = pw.Document();
                      final fontData = await rootBundle.load(
                        'assets/fonts/Helvetica-Bold.ttf',
                      );
                      final ttf = pw.Font.ttf(fontData);

                      pdf.addPage(
                        pw.Page(
                          pageFormat: PdfPageFormat.a4,
                          build: (pw.Context context) {
                            return pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'Mesa ${table.number}',
                                    style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 24,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 20),
                                  pw.Image(
                                    pw.MemoryImage(qrImage),
                                    width: 300,
                                    height: 300,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );

                      await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => pdf.save(),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al imprimir el QR: $e'),
                          backgroundColor: const Color(0xFFD91010),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  Future<Uint8List> _generateQRImage(Map<String, dynamic> qrData) async {
    try {
      final qrPainter = QrPainter(
        data: jsonEncode(qrData),
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      final imageData = await qrPainter.toImageData(300.0);
      if (imageData == null) {
        throw Exception('No se pudo generar la imagen del QR');
      }
      return imageData.buffer.asUint8List();
    } catch (e) {
      throw Exception('Error al generar la imagen del QR: $e');
    }
  }
}
