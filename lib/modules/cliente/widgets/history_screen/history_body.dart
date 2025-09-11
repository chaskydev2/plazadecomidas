import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_card.dart';
import 'loading_state.dart';
import 'empty_state.dart';

typedef FetchOrdersPage =
    Future<List<ClientOrder>> Function({
      ClientOrder? lastOrder,
      int limit,
      required int tabIndex,
      DateTimeRange? dateRange,
    });

class HistoryBody extends StatefulWidget {
  final int tabIndex;
  final DateTimeRange? dateRange;
  final void Function(double)?
  onTotalSum; // opcional (no usado si calculas en el padre)
  final FetchOrdersPage fetchOrders;

  const HistoryBody({
    super.key,
    required this.tabIndex,
    this.dateRange,
    this.onTotalSum,
    required this.fetchOrders,
  });

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  final ScrollController _scrollController = ScrollController();
  final List<ClientOrder> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  ClientOrder? _lastOrder;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);

    try {
      final newOrders = await widget.fetchOrders(
        lastOrder: _lastOrder,
        limit: _pageSize,
        tabIndex: widget.tabIndex,
        dateRange: widget.dateRange,
      );

      if (!mounted) return;
      setState(() {
        _orders.addAll(newOrders);
        _isLoading = false;
        _hasMore = newOrders.length == _pageSize;
        if (_orders.isNotEmpty) _lastOrder = _orders.last;

        // Si quieres total incremental (de lo cargado), descomenta:
        // widget.onTotalSum?.call(_orders.fold(0.0, (sum, o) => sum + o.total));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Podrías mostrar un snackbar de error aquí si lo deseas
    }
  }

  @override
  void didUpdateWidget(covariant HistoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.dateRange != widget.dateRange) {
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    setState(() {
      _orders.clear();
      _lastOrder = null;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty && _isLoading) return const LoadingState();
    if (_orders.isEmpty) {
      return const EmptyState(
        message: '¡Aún no tienes pedidos en esta categoría!',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _orders.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < _orders.length) {
          return OrderCard(
            order: _orders[i],
            onDelete: () async {
              final orderToDelete = _orders[i];
              // No permitir eliminar si está en progreso o listo
              if (orderToDelete.status == OrderStatus.inProgress ||
                  orderToDelete.status == OrderStatus.ready) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No puedes eliminar pedidos en progreso o listos para entregar.',
                      ),
                    ),
                  );
                }
                return;
              }
              setState(() {
                _orders.removeAt(i);
              });
              try {
                final userId = orderToDelete.userId;
                await _deleteOrderFromFirestore(userId, orderToDelete.id);
                // Eliminar también de la colección de pedidos del restaurante
                await _deleteOrderFromRestaurant(
                  orderToDelete.restaurantId,
                  orderToDelete.id,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                  _resetAndLoad();
                }
              }
            },
          );
        } else {
          // Loader de paginación
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Future<void> _deleteOrderFromFirestore(String userId, String orderId) async {
    // Elimina el pedido del historial del usuario en Firestore
    final fs = FirebaseFirestore.instance;
    await fs
        .collection('users')
        .doc(userId)
        .collection('order_history')
        .doc(orderId)
        .delete();
  }

  Future<void> _deleteOrderFromRestaurant(
    String restaurantId,
    String orderId,
  ) async {
    final fs = FirebaseFirestore.instance;
    await fs
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .doc(orderId)
        .delete();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
