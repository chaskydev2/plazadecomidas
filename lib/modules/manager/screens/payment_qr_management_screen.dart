import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../services/payment_service.dart';
import '../../../models/payment_qr.dart';
import '../../../models/payment_receipt.dart';
import '../../../core/themes/app_colors.dart';

class PaymentQRManagementScreen extends StatefulWidget {
  final String restaurantId;

  const PaymentQRManagementScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  _PaymentQRManagementScreenState createState() =>
      _PaymentQRManagementScreenState();
}

class _PaymentQRManagementScreenState extends State<PaymentQRManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Mi QR de Pagos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Mi QR', icon: Icon(Icons.qr_code_2)),
            Tab(text: 'Comprobantes', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QRConfigTab(
            restaurantId: widget.restaurantId,
            paymentService: _paymentService,
          ),
          _ReceiptsTab(
            restaurantId: widget.restaurantId,
            paymentService: _paymentService,
          ),
        ],
      ),
    );
  }
}

// =================== TAB DE CONFIGURACIÓN DEL QR ===================

class _QRConfigTab extends StatefulWidget {
  final String restaurantId;
  final PaymentService paymentService;

  const _QRConfigTab({
    required this.restaurantId,
    required this.paymentService,
  });

  @override
  _QRConfigTabState createState() => _QRConfigTabState();
}

class _QRConfigTabState extends State<_QRConfigTab> {
  PaymentQR? _currentQR;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadQR();
  }

  Future<void> _loadQR() async {
    setState(() => _isLoading = true);
    try {
      final qr = await widget.paymentService.getRestaurantPaymentQR(
        widget.restaurantId,
      );
      setState(() {
        _currentQR = qr;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _EditQRScreen(
              restaurantId: widget.restaurantId,
              currentQR: _currentQR,
              paymentService: widget.paymentService,
            ),
      ),
    );

    if (result == true) {
      _loadQR(); // Recargar el QR
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQR == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Aún no has configurado\ntu QR de pagos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Configura tu QR para que tus clientes\npuedan pagar con transferencia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _editQR,
                icon: const Icon(Icons.add),
                label: const Text('Configurar QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta con el QR
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'QR de Pago Actual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _currentQR!.qrImageUrl,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 250,
                          height: 250,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Información bancaria
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Bancaria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Banco:', _currentQR!.bankName),
                        _buildInfoRow('Titular:', _currentQR!.accountHolder),
                        _buildInfoRow('Cuenta:', _currentQR!.accountNumber),
                        _buildInfoRow('Tipo:', _currentQR!.accountType),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Última actualización:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(_currentQR!.updatedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Botón de editar
          ElevatedButton.icon(
            onPressed: _editQR,
            icon: const Icon(Icons.edit),
            label: const Text('Editar QR y Datos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================== PANTALLA DE EDICIÓN DEL QR ===================

class _EditQRScreen extends StatefulWidget {
  final String restaurantId;
  final PaymentQR? currentQR;
  final PaymentService paymentService;

  const _EditQRScreen({
    required this.restaurantId,
    this.currentQR,
    required this.paymentService,
  });

  @override
  _EditQRScreenState createState() => _EditQRScreenState();
}

class _EditQRScreenState extends State<_EditQRScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountTypeController = TextEditingController();

  File? _qrImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentQR != null) {
      _bankNameController.text = widget.currentQR!.bankName;
      _accountHolderController.text = widget.currentQR!.accountHolder;
      _accountNumberController.text = widget.currentQR!.accountNumber;
      _accountTypeController.text = widget.currentQR!.accountType;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _accountTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _qrImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveQR() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_qrImageFile == null && widget.currentQR == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una imagen del QR'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.paymentService.savePaymentQR(
        restaurantId: widget.restaurantId,
        qrImageFile: _qrImageFile!,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountHolder: _accountHolderController.text.trim(),
        accountType: _accountTypeController.text.trim(),
        existingQRId: widget.currentQR?.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR de pago guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.currentQR == null ? 'Configurar QR' : 'Editar QR',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isSaving
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Guardando...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Área de la imagen del QR
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 280,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[50],
                          ),
                          child:
                              _qrImageFile != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _qrImageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : widget.currentQR != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      widget.currentQR!.qrImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Toca para seleccionar\nla imagen del QR',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Formulario
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Banco',
                          hintText: 'Ej: Banco Nacional de Bolivia',
                          prefixIcon: const Icon(Icons.account_balance),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre del banco';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountHolderController,
                        decoration: InputDecoration(
                          labelText: 'Titular de la Cuenta',
                          hintText: 'Nombre completo del titular',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el titular de la cuenta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          labelText: 'Número de Cuenta',
                          hintText: 'Ej: 1234567890',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el número de cuenta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountTypeController,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Cuenta',
                          hintText: 'Ej: Ahorro, Corriente',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el tipo de cuenta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Botón de guardar
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveQR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            widget.currentQR == null
                                ? 'Guardar QR'
                                : 'Actualizar QR',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
}

// =================== TAB DE COMPROBANTES ===================

class _ReceiptsTab extends StatelessWidget {
  final String restaurantId;
  final PaymentService paymentService;

  const _ReceiptsTab({
    required this.restaurantId,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentReceipt>>(
      stream: paymentService.getRestaurantReceipts(restaurantId: restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final receipts = snapshot.data ?? [];

        if (receipts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text(
                    'No hay comprobantes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Los comprobantes de pago de tus clientes\naparecerán aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: receipts.length,
          itemBuilder: (context, index) {
            final receipt = receipts[index];
            return _ReceiptCard(
              receipt: receipt,
              paymentService: paymentService,
            );
          },
        );
      },
    );
  }
}

// =================== TARJETA DE COMPROBANTE ===================

class _ReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;
  final PaymentService paymentService;

  const _ReceiptCard({required this.receipt, required this.paymentService});

  Future<void> _viewReceipt(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _ReceiptDetailScreen(
              receipt: receipt,
              paymentService: paymentService,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewReceipt(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(
                        PaymentReceipt.getStatusColor(receipt.status),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: Color(
                        PaymentReceipt.getStatusColor(receipt.status),
                      ),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(receipt.submittedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bs. ${receipt.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            PaymentReceipt.getStatusColor(receipt.status),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          PaymentReceipt.getStatusText(receipt.status),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== PANTALLA DE DETALLE DEL COMPROBANTE ===================

class _ReceiptDetailScreen extends StatefulWidget {
  final PaymentReceipt receipt;
  final PaymentService paymentService;

  const _ReceiptDetailScreen({
    required this.receipt,
    required this.paymentService,
  });

  @override
  _ReceiptDetailScreenState createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<_ReceiptDetailScreen> {
  bool _isProcessing = false;

  Future<void> _approveReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Aprobar Comprobante'),
            content: const Text(
              '¿Confirmas que recibiste el pago?\n\nEsto marcará el pedido como pagado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Aprobar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');

      await widget.paymentService.approveReceipt(widget.receipt.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante aprobado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectReceipt() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rechazar Comprobante'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Explica el motivo del rechazo:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ej: Monto incorrecto, imagen borrosa...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Rechazar'),
              ),
            ],
          ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No autenticado');

      await widget.paymentService.rejectReceipt(
        widget.receipt.id,
        user.uid,
        reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante rechazado'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Detalle del Comprobante',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información del pago
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Pago',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Cliente:', widget.receipt.userName),
                            _buildInfoRow(
                              'Monto:',
                              'Bs. ${widget.receipt.amount.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Fecha:',
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(widget.receipt.submittedAt),
                            ),
                            _buildInfoRow(
                              'Estado:',
                              PaymentReceipt.getStatusText(
                                widget.receipt.status,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Imagen del comprobante
                    const Text(
                      'Comprobante:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.receipt.receiptImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 400,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Botones de acción (solo si está pendiente)
                    if (widget.receipt.status == ReceiptStatus.pending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _rejectReceipt,
                              icon: const Icon(Icons.close),
                              label: const Text('Rechazar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _approveReceipt,
                              icon: const Icon(Icons.check),
                              label: const Text('Aprobar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
