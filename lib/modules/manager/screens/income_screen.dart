// IMPORTACIONES PRINCIPALES
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/manager/models/ingreso.dart';
import 'package:kokorestaurant/modules/manager/services/ingreso_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class IncomeScreen extends StatefulWidget {
  final String restaurantId;

  const IncomeScreen({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final IngresoService _ingresoService = IngresoService();
  late DateTimeRange _dateRange;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'Bs. ',
    decimalDigits: 2,
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Ingreso> _allIngresos = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day - 30),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  List<Ingreso> _filterIngresos(List<Ingreso> ingresos) {
    return ingresos.where((ingreso) {
      final matchPedido = ingreso.numeroPedido.toString().contains(
        _searchQuery,
      );
      final matchItems = ingreso.items.any(
        (item) => item.name.toLowerCase().contains(_searchQuery),
      );
      return matchPedido || matchItems;
    }).toList();
  }

  void _printSingleIngreso(Ingreso ingreso) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen del Pedido',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Número de Pedido: #${ingreso.numeroPedido.toString().padLeft(3, '0')}',
                ),
                pw.Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(ingreso.fecha)}',
                ),
                pw.Text(
                  'Monto Total: ${_currencyFormat.format(ingreso.monto)}',
                ),
                pw.Text('Método de pago: ${ingreso.metodoPago ?? "N/A"}'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Ítems:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...ingreso.items.map(
                  (item) => pw.Bullet(
                    text:
                        '${item.quantity} x ${item.name} (${_currencyFormat.format(item.price)})'
                        '${item.notes != null ? ' — Nota: ${item.notes}' : ''}',
                  ),
                ),
                if (ingreso.notas != null && ingreso.notas!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Notas adicionales:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(ingreso.notas!),
                ],
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportToPDF(List<Ingreso> ingresos) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Resumen de Ingresos',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ...ingresos.map(
                (ing) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pedido #${ing.numeroPedido} - ${_currencyFormat.format(ing.monto)}',
                    ),
                    pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(ing.fecha)),
                    pw.Text('Método: ${ing.metodoPago ?? "N/A"}'),
                    pw.Text('${ing.items.length} ítems'),
                    pw.Divider(),
                  ],
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final ingresosFiltrados = _filterIngresos(_allIngresos);
    final totalFiltrado = ingresosFiltrados.fold<double>(
      0,
      (sum, ing) => sum + ing.monto,
    );
    final totalGeneral = _allIngresos.fold<double>(
      0,
      (sum, ing) => sum + ing.monto,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos del Restaurante'),
        backgroundColor: AppColors.second,
        foregroundColor: Colors.white, // Para texto e íconos en blanco
        iconTheme: const IconThemeData(color: Colors.white), // Íconos en blanco
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Exportar a PDF',
            onPressed: () => _exportToPDF(ingresosFiltrados),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalIngresos(totalFiltrado, totalGeneral),
          _buildCustomDateRangeCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Buscar por ítem o número de pedido',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildIncomeList()),
        ],
      ),
    );
  }

  Widget _buildTotalIngresos(double totalFiltrado, double totalGeneral) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(totalGeneral),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(221, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.credit_card,
                      size: 20,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRangeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rango de fechas',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.second,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.primary,
            ),
            label: const Text(
              'Cambiar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeList() {
    return StreamBuilder<List<Ingreso>>(
      stream: _ingresoService.obtenerIngresos(
        widget.restaurantId,
        fechaInicio: _dateRange.start,
        fechaFin: _dateRange.end,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        _allIngresos = snapshot.data ?? [];
        final ingresosFiltrados = _filterIngresos(_allIngresos);

        if (ingresosFiltrados.isEmpty) {
          return const Center(child: Text('No se encontraron ingresos.'));
        }

        return ListView.builder(
          itemCount: ingresosFiltrados.length,
          itemBuilder:
              (context, index) => _buildIncomeItem(ingresosFiltrados[index]),
        );
      },
    );
  }

  Widget _buildIncomeItem(Ingreso ingreso) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      color: AppColors.second, // Fondo del card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showIncomeDetails(ingreso),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera línea: Número de pedido y monto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${ingreso.numeroPedido.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(ingreso.monto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Segunda línea: Fecha y cantidad de ítems
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy – HH:mm').format(ingreso.fecha),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  Text(
                    '${ingreso.items.length} ítem${ingreso.items.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Botón de imprimir
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () => _printSingleIngreso(ingreso),
                  icon: const Icon(
                    Icons.print,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Imprimir',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncomeDetails(Ingreso ingreso) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Detalles del Ingreso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Número de Pedido',
                  '#${ingreso.numeroPedido.toString().padLeft(3, '0')}',
                ),
                _buildDetailRow(
                  'Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(ingreso.fecha),
                ),
                _buildDetailRow(
                  'Monto Total',
                  _currencyFormat.format(ingreso.monto),
                ),
                if (ingreso.metodoPago != null)
                  _buildDetailRow('Método de pago', ingreso.metodoPago!),
                const SizedBox(height: 16),
                const Text(
                  'Ítems del pedido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ...ingreso.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    trailing: Text(
                      '${item.quantity} x ${_currencyFormat.format(item.price)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        item.notes != null
                            ? Text('Nota: ${item.notes!}')
                            : null,
                  ),
                ),
                if (ingreso.notas != null && ingreso.notas!.isNotEmpty) ...{
                  const SizedBox(height: 16),
                  const Text(
                    'Notas adicionales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  Text(ingreso.notas!),
                },
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
