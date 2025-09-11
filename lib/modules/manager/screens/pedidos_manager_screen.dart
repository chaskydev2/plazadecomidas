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

class PedidosManagerScreen extends StatefulWidget {
  final String restaurantId;

  const PedidosManagerScreen({super.key, required this.restaurantId});

  @override
  State<PedidosManagerScreen> createState() => _PedidosManagerScreenState();
}

class _PedidosManagerScreenState extends State<PedidosManagerScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngresoService _ingresoService = IngresoService();
  late TabController _tabController;

  int _todos = 0;
  int _pendientes = 0;
  int _listos = 0;
  int _entregados = 0;
  int _cancelados = 0;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrderCounts();
  }

  Future<void> _fetchOrderCounts() async {
    final snapshot =
        await _firestore
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('orders')
            .get();

    int todos = 0;
    int pendientes = 0;
    int listos = 0;
    int entregados = 0;
    int cancelados = 0;

    for (var doc in snapshot.docs) {
      todos++;
      final data = doc.data();
      final status = data['status'];
      if (status == 'pending') pendientes++;
      if (status == 'ready') listos++;
      if (status == 'delivered') entregados++;
      if (status == 'cancelled') cancelados++;
    }

    setState(() {
      _todos = todos;
      _pendientes = pendientes;
      _listos = listos;
      _entregados = entregados;
      _cancelados = cancelados;
      DateTimeRange? _selectedDateRange;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final doc =
          await _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('orders')
              .doc(orderId)
              .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final pedido = ClientOrder.fromJson({...data, 'id': doc.id});

      final currentStatus = OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${doc['status']}',
        orElse: () => OrderStatus.pending,
      );

      if (currentStatus == OrderStatus.delivered) return;

      await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus.toString().split('.').last,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (newStatus == OrderStatus.delivered) {
        final ingreso = Ingreso.desdePedido(pedido);
        await _ingresoService.guardarIngreso(ingreso);
      }

      await _fetchOrderCounts(); // <-- Actualiza contadores después de cambiar estado

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a: ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _limpiarPedidosEntregados() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¿Eliminar pedidos entregados?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Esta acción eliminará de forma permanente todos los pedidos ya entregados del sistema.\n\n¿Estás seguro de que quieres continuar?',
              style: TextStyle(fontSize: 15.5, color: Colors.black87),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.delete_forever, size: 20),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final overlaySize = overlay.size;
      final loader = OverlayEntry(
        builder:
            (context) => Container(
              color: Colors.black54,
              width: overlaySize.width,
              height: overlaySize.height,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
      );

      Overlay.of(context).insert(loader);

      final querySnapshot =
          await _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('orders')
              .where(
                'status',
                isEqualTo: OrderStatus.delivered.toString().split('.').last,
              )
              .get();

      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      loader.remove();

      await _fetchOrderCounts(); // <-- Actualiza contadores después de limpiar

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedidos entregados eliminados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar los pedidos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarPedidosFiltrados(List<ClientOrder> orders) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Eliminar estos pedidos?'),
            content: Text(
              'Se eliminarán ${orders.length} pedidos mostrados. ¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      final batch = _firestore.batch();

      for (var order in orders) {
        final docRef = _firestore
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('orders')
            .doc(order.id);
        batch.delete(docRef);
      }

      await batch.commit();
      await _fetchOrderCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${orders.length} pedidos eliminados.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildTabs(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.date_range, size: 20),
                  ),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text("Filtrar por fecha"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                if (_selectedDateRange != null)
                  ElevatedButton.icon(
                    onPressed: _clearDateRange,
                    icon: const Icon(Icons.clear),
                    label: const Text("Limpiar filtro"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildOrdersTab(filter: OrderStatus.pending),
                _buildOrdersTab(filter: OrderStatus.inProgress),
                _buildOrdersTab(filter: OrderStatus.delivered),
                _buildOrdersTab(filter: OrderStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _limpiarPedidosEntregados,
        icon: const Icon(Icons.cleaning_services),
        label: const Text('Limpiar Entregados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.second,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: const Color(0xFFF5F5DC),
          labelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.5,
          ),
          tabs: [
            Tab(text: 'Todos ($_todos)'),
            Tab(text: 'Pendiente ($_pendientes)'),
            Tab(text: 'Progreso ($_listos)'),
            Tab(text: 'Completados ($_entregados)'),
            Tab(text: 'Cancelados ($_cancelados)'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildOrdersTab({OrderStatus? filter}) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('orders')
              .orderBy('orderNumber', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar los pedidos',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final orders =
            docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ClientOrder.fromJson({...data, 'id': doc.id});
                })
                .where((order) => filter == null || order.status == filter)
                .toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay pedidos',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index], context);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(ClientOrder order, BuildContext context) {
    return _OrderCardContent(order: order, parentContext: context);
  }
}

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
          OrderStatus.pending: AppColors.primary.withOpacity(
            0.8,
          ), // naranja suave
          OrderStatus.confirmed: Colors.blueGrey,
          OrderStatus.inProgress: const Color(0xFF8E24AA), // púrpura fuerte
          OrderStatus.ready: Colors.green[600]!,
          OrderStatus.delivered: Colors.teal[700]!,
          OrderStatus.cancelled: Colors.red[800]!,
        }[widget.order.status] ??
        Colors.grey;

    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    final formattedDate = dateFormat.format(widget.order.createdAt);
    final formattedOrderNumber = widget.order.orderNumber.toString().padLeft(
      3,
      '0',
    );

    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    color: AppColors.white,
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
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
    final _PedidosManagerScreenState parent =
        context.findAncestorStateOfType<_PedidosManagerScreenState>()!;
    switch (order.status) {
      case OrderStatus.pending:
        return [
          TextButton.icon(
            onPressed:
                () =>
                    parent._updateOrderStatus(order.id, OrderStatus.cancelled),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed:
                () =>
                    parent._updateOrderStatus(order.id, OrderStatus.confirmed),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ];
      case OrderStatus.confirmed:
        return [
          ElevatedButton.icon(
            onPressed:
                () =>
                    parent._updateOrderStatus(order.id, OrderStatus.inProgress),
            icon: const Icon(Icons.restaurant_menu, size: 16),
            label: const Text('En preparación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[50],
              foregroundColor: Colors.purple[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ];
      case OrderStatus.inProgress:
        return [
          ElevatedButton.icon(
            onPressed:
                () => parent._updateOrderStatus(order.id, OrderStatus.ready),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Marcar como listo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ];
      case OrderStatus.ready:
        return [
          ElevatedButton.icon(
            onPressed:
                () =>
                    parent._updateOrderStatus(order.id, OrderStatus.delivered),
            icon: const Icon(Icons.delivery_dining, size: 16),
            label: const Text('Marcar como entregado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
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
