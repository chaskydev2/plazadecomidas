import 'package:flutter/material.dart';

class HistoryTabs extends StatelessWidget {
  final TabController controller;
  final Color background;
  final Color indicator;
  final VoidCallback? onTap;

  const HistoryTabs({
    super.key,
    required this.controller,
    required this.background,
    required this.indicator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: TabBar(
          controller: controller,
          onTap: (_) => onTap?.call(),
          indicator: BoxDecoration(
            color: indicator,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: background,
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
            Tab(child: FittedBox(child: Text('Todos'))),
            Tab(child: FittedBox(child: Text('Pendiente'))),
            Tab(child: FittedBox(child: Text('Progreso'))),
            Tab(child: FittedBox(child: Text('Completados'))),
          ],
        ),
      ),
    );
  }
}
