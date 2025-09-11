import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class StatisticsDetailScreen extends StatefulWidget {
  final String restaurantId;

  const StatisticsDetailScreen({Key? key, required this.restaurantId}) : super(key: key);

  @override
  _StatisticsDetailScreenState createState() => _StatisticsDetailScreenState();
}

class _StatisticsDetailScreenState extends State<StatisticsDetailScreen> {
  final AdminService _adminService = AdminService();
  String _selectedPeriod = 'week';
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _adminService.getRestaurantPerformance(widget.restaurantId);
      setState(() {
        _statistics = stats.isNotEmpty ? stats.first : {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Estadísticas Detalladas', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            items: const [
              DropdownMenuItem(value: 'day', child: Text('Día')),
              DropdownMenuItem(value: 'week', child: Text('Semana')),
              DropdownMenuItem(value: 'month', child: Text('Mes')),
              DropdownMenuItem(value: 'year', child: Text('Año')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPeriod = newValue;
                });
                _loadStatistics();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsCard(
              'Ventas Totales',
              '\$${_statistics['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatisticsCard(
              'Órdenes',
              '${_statistics['totalOrders'] ?? '0'}',
              Icons.shopping_cart,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatisticsCard(
              'Productos Vendidos',
              '${_statistics['totalProducts'] ?? '0'}',
              Icons.restaurant,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Productos Más Vendidos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTopProductsList(),
            const SizedBox(height: 24),
            const Text(
              'Gráfico de Ventas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSalesChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    final topProducts = _statistics['topProducts'] as List? ?? [];
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topProducts.length,
        itemBuilder: (context, index) {
          final product = topProducts[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(product['name'] ?? ''),
            subtitle: Text('${product['quantity']} unidades vendidas'),
            trailing: Text('\$${product['total'].toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }

  Widget _buildSalesChart() {
    // Aquí podrías implementar un gráfico usando una librería como fl_chart
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('Gráfico de ventas (implementar con fl_chart)'),
      ),
    );
  }
} 