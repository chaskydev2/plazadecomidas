import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kokorestaurant/modules/admin/services/branch_service.dart';

class BottomSummaryBar extends StatefulWidget {
  final String address;
  final String idRestaurant;
  final double total;
  final bool isSending;
  final bool isDisabled;
  final VoidCallback onSend;
  final ValueChanged<String?>? onBranchChanged;

  const BottomSummaryBar({
    super.key,
    required this.address,
    required this.idRestaurant,
    required this.total,
    required this.isSending,
    required this.isDisabled,
    required this.onSend,
    this.onBranchChanged,
  });

  @override
  State<BottomSummaryBar> createState() => _BottomSummaryBarState();
}

class _BottomSummaryBarState extends State<BottomSummaryBar> {
  final BranchService _branchService = BranchService();
  List<Map<String, dynamic>> _branches = [];
  bool _loadingBranches = true;
  Map<String, dynamic>? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    // imprime el id del restaurante
    print('idRestaurant: ${widget.idRestaurant}');

    try {
      final branches =
          await _branchService.getBranchesWithRestaurant(widget.idRestaurant) ??
          [];

      print('branches.length = [32m${branches.length}[0m');
      for (var i = 0; i < branches.length; i++) {
        print('Branch[$i]: ${branches[i]}');
      }

      if (!mounted) return;
      setState(() {
        _branches = branches;
        _loadingBranches = false;
        if (_branches.isNotEmpty) {
          _selectedBranch = _branches.first;
          if (widget.onBranchChanged != null) {
            widget.onBranchChanged!(_selectedBranch?['id'] as String?);
          }
        }
      });
    } catch (e) {
      print('Error cargando sucursales: $e');
      if (!mounted) return;
      setState(() {
        _branches = [];
        _loadingBranches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF111827)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubicación de Entrega',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Selector de sucursal
                  if (_loadingBranches)
                    const Text(
                      "Cargando sucursales...",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    )
                  else if (_branches.isEmpty)
                    Text(
                      widget.address,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    )
                  else ...[
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedBranch,
                          isDense: true, // Hace el dropdown más compacto
                          dropdownColor: const Color(0xFF23272F),
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          isExpanded: true,
                          items:
                              _branches.map((branch) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: branch,
                                  child: Text(
                                    branch['nombre'] ?? 'Sucursal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (branch) {
                            setState(() {
                              _selectedBranch = branch;
                            });
                            if (widget.onBranchChanged != null) {
                              widget.onBranchChanged!(branch?['id'] as String?);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedBranch?['direccion'] ?? widget.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sección total + botón
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Total\n',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: 'Bs${widget.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              (widget.isDisabled || widget.isSending)
                                  ? null
                                  : widget.onSend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6243),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                          ),
                          child:
                              widget.isSending
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : const Text('Realizar Pedido'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
