import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/cliente/models/order.dart';
import 'package:kokorestaurant/modules/cliente/services/history_service.dart';
import 'package:kokorestaurant/modules/cliente/widgets/history_screen/history_body.dart';

enum DateFilter { all, today, range }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final HistoryService _historyService = HistoryService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  DateFilter _selectedFilter = DateFilter.all;
  DateTimeRange? _dateRange; // usado sólo cuando _selectedFilter == range
  double _totalActual = 0.0;

  // Cache local (alimentado por stream)
  List<ClientOrder> _cache = [];
  bool _cacheLoaded = false;
  StreamSubscription<List<ClientOrder>>? _sub;

  // 👇 Cada vez que cambia el stream, incrementa para forzar rebuild de HistoryBody
  int _cacheEpoch = 0;

  @override
  void initState() {
    super.initState();
    // 7 pestañas: Todos, Pendiente, Confirmado, En progreso, Listo, Entregado, Cancelado
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        _recomputeTotal();
        setState(() {});
      }
    });
    _startLive(); // suscripción en tiempo real
  }

  void _startLive() {
    if (_currentUser == null) return;
    _sub?.cancel();
    _sub = _historyService.getUserOrderHistory(_currentUser!.uid).listen((list) {
      _cache = List<ClientOrder>.from(list)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // recientes primero
      _cacheLoaded = true;
      _recomputeTotal();
      _cacheEpoch++; // 👈 fuerza que HistoryBody se reconstruya y recargue páginas
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Recalcula el total global según tab + rango actual usando el cache
  void _recomputeTotal() {
    final filtered = _applyFilters(
      _cache,
      _tabController.index,
      _effectiveRange(),
    );
    final sum = filtered.fold<double>(0.0, (s, o) => s + o.total);
    _totalActual = sum;
  }

  // Filtro por tab y rango
  List<ClientOrder> _applyFilters(
    List<ClientOrder> source,
    int tabIndex,
    DateTimeRange? range,
  ) {
    Iterable<ClientOrder> data = source;

    // por pestaña (7)
    switch (tabIndex) {
      case 1: // Pendiente
        data = data.where((o) => o.status == OrderStatus.pending);
        break;
      case 2: // Confirmado
        data = data.where((o) => o.status == OrderStatus.confirmed);
        break;
      case 3: // En progreso
        data = data.where((o) => o.status == OrderStatus.inProgress);
        break;
      case 4: // Listo
        data = data.where((o) => o.status == OrderStatus.ready);
        break;
      case 5: // Entregado
        data = data.where((o) => o.status == OrderStatus.delivered);
        break;
      case 6: // Cancelado
        data = data.where((o) => o.status == OrderStatus.cancelled);
        break;
      default: // 0: Todos
        break;
    }

    // por rango de fechas
    if (range != null) {
      data = data.where(
        (o) =>
            !o.createdAt.isBefore(range.start) &&
            !o.createdAt.isAfter(range.end),
      );
    }

    return data.toList();
  }

  // Callback que HistoryBody usará para pedir páginas (paginación en memoria)
  Future<List<ClientOrder>> _fetchOrdersPage({
    ClientOrder? lastOrder,
    int limit = 20,
    required int tabIndex,
    DateTimeRange? dateRange,
  }) async {
    // Si aún no cargó el primer snapshot en vivo, devolvemos vacío (se repintará cuando llegue)
    if (!_cacheLoaded) {
      return [];
    }

    // Filtramos según tab + rango
    final filtered = _applyFilters(_cache, tabIndex, dateRange);

    // Actualiza el total global (según filtro actual)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _totalActual = filtered.fold<double>(0.0, (s, o) => s + o.total);
      });
    });

    // Paginación en memoria
    int startIndex = 0;
    if (lastOrder != null) {
      startIndex = filtered.indexWhere((o) {
        final sameNumber = (o.orderNumber == lastOrder.orderNumber); // suele ser único
        final sameTime = o.createdAt == lastOrder.createdAt;
        return sameNumber || sameTime;
      });
      if (startIndex != -1) startIndex += 1; // comenzar después del último
      if (startIndex == -1) startIndex = 0;
    }

    final page = filtered.skip(startIndex).take(limit).toList();
    return page;
  }

  void _setTodayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    setState(() {
      _selectedFilter = DateFilter.today;
      _dateRange = DateTimeRange(start: start, end: end);
      _recomputeTotal();
      _cacheEpoch++; // 👈 para refrescar HistoryBody con el nuevo rango
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          ),
      helpText: 'Selecciona un rango',
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedFilter = DateFilter.range;
        // Normalizamos a inicio y fin del día
        final start = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        final end = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        );
        _dateRange = DateTimeRange(start: start, end: end);
        _recomputeTotal();
        _cacheEpoch++; // 👈 para refrescar HistoryBody con el nuevo rango
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedFilter = DateFilter.all;
      _dateRange = null;
      _recomputeTotal();
      _cacheEpoch++; // 👈 para refrescar HistoryBody al limpiar
    });
  }

  DateTimeRange? _effectiveRange() {
    switch (_selectedFilter) {
      case DateFilter.all:
        return null;
      case DateFilter.today:
      case DateFilter.range:
        return _dateRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const _LoginRequired();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ---- Tabs (mismo diseño) pero con 7 estados ----
          Container(
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
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Pendiente'),
                  Tab(text: 'Confirmado'),
                  Tab(text: 'En progreso'),
                  Tab(text: 'Listo'),
                  Tab(text: 'Entregado'),
                  Tab(text: 'Cancelado'),
                ],
                onTap: (_) => setState(() {}),
              ),
            ),
          ),

          // ---- Barra de filtros + Total (sin cambios de diseño) ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _FiltersBar(
              selected: _selectedFilter,
              onAll: _clearFilter,
              onToday: _setTodayRange,
              onRange: _pickRange,
              dateRangeLabel:
                  _selectedFilter == DateFilter.range && _dateRange != null
                      ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                      : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _TotalBar(total: _totalActual),
          ),

          // ---- Lista / Body con scroll infinito (alimentado por cache en vivo) ----
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                // 👇 KEY cambia cuando llega un snapshot o cambias rango/tab ⇒ rebuild total
                final bodyKey = ValueKey('history-body-${_tabController.index}-$_cacheEpoch');

                return HistoryBody(
                  key: bodyKey, // 👈 fuerza a recrear HistoryBody y refrescar su data
                  tabIndex: _tabController.index,
                  dateRange: _effectiveRange(),
                  // No pasamos onTotalSum porque calculamos con cache global
                  fetchOrders: ({
                    ClientOrder? lastOrder,
                    int limit = 20,
                    required int tabIndex,
                    DateTimeRange? dateRange,
                  }) {
                    return _fetchOrdersPage(
                      lastOrder: lastOrder,
                      limit: limit,
                      tabIndex: tabIndex,
                      dateRange: dateRange,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: Colors.grey),
              SizedBox(height: 15),
              Text(
                '¡Inicia sesión para ver tu historial de pedidos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 222, 125, 125),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final DateFilter selected;
  final VoidCallback onAll;
  final VoidCallback onToday;
  final VoidCallback onRange;
  final String? dateRangeLabel;

  const _FiltersBar({
    required this.selected,
    required this.onAll,
    required this.onToday,
    required this.onRange,
    this.dateRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final chipStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selected == DateFilter.all,
          onSelected: (_) => onAll(),
          labelStyle: chipStyle,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Hoy'),
          selected: selected == DateFilter.today,
          onSelected: (_) => onToday(),
          labelStyle: chipStyle,
        ),
        const SizedBox(width: 8),
        ActionChip(
          label: Text(dateRangeLabel ?? 'Rango'),
          onPressed: onRange,
          labelStyle: chipStyle,
          avatar: const Icon(Icons.date_range_rounded, size: 18),
        ),
      ],
    );
  }
}

class _TotalBar extends StatelessWidget {
  final double total;
  const _TotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Total de pedidos filtrados',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          const Spacer(),
          Text(
            'Bs. ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16.5,
              color: Color(0xFFFF5722),
            ),
          ),
        ],
      ),
    );
  }
}
