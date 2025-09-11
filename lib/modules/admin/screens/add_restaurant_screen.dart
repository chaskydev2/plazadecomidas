import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/admin/services/admin_service.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';

import 'package:kokorestaurant/modules/admin/widgets/image_picker_tile.dart';
import 'package:kokorestaurant/modules/admin/widgets/labeld_field.dart';
import 'package:kokorestaurant/modules/admin/widgets/section_title.dart';

/// Pantalla para crear/editar restaurante con UI pulida y código modular.
class AddRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;
  final bool isEdit;
  const AddRestaurantScreen({Key? key, this.restaurant})
    : isEdit = restaurant != null,
      super(key: key);

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  bool _isEspecial = true;
  // Simula la obtención de categorías desde Firestore (ajusta según tu servicio real)
  Future<List<Map<String, dynamic>>> _getCategorieFood() async {
    final snap =
        await FirebaseFirestore.instance.collection('categorie-food').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'category': data['category'] ?? ''};
    }).toList();
  }

  String? _selectedCategoryId;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _locationUrlController;

  // Imagen de portada
  XFile? _coverXFile;
  Uint8List? _coverBytes; // web
  String? _initialImageUrl;

  // Logo
  XFile? _logoXFile;
  Uint8List? _logoBytes; // web
  String? _initialLogoUrl;

  // Horarios y días
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;
  final List<String> _daysOfWeek = const [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];
  late List<bool> _selectedDays;

  // Estado
  bool _isLoading = false;
  final _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    // Inicializar _isEspecial si se edita
    if (r != null && r.isEspecial != null) {
      _isEspecial = r.isEspecial;
    }

    _nameController = TextEditingController(text: r?.name ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _locationController = TextEditingController(text: r?.location ?? '');
    _locationUrlController = TextEditingController(
      text: r?.googleMapsUrl ?? '',
    );

    _initialImageUrl = r?.imageUrl;
    _initialLogoUrl = r?.logoUrl;

    // Horarios
    if (r != null && r.openHours.isNotEmpty) {
      _openingTime = _parseTime(r.openHours['opening']);
      _closingTime = _parseTime(r.openHours['closing']);
    } else {
      _openingTime = const TimeOfDay(hour: 9, minute: 0);
      _closingTime = const TimeOfDay(hour: 18, minute: 0);
    }

    // Días
    if (r != null && r.openDays.isNotEmpty) {
      _selectedDays = _daysOfWeek.map((d) => r.openDays.contains(d)).toList();
    } else {
      _selectedDays = List<bool>.filled(7, false);
    }

    // Categoría (si viene del modelo)
    _selectedCategoryId =
        r != null && r.idCategoriaFood != null ? r.idCategoriaFood : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  // --- Helpers ---
  TimeOfDay _parseTime(dynamic value) {
    if (value is String && value.contains(':')) {
      final parts = value.split(':');
      final h = int.tryParse(parts[0]) ?? 9;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _timeTo24h(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isLogo) {
          _logoXFile = picked;
          _logoBytes = bytes;
        } else {
          _coverXFile = picked;
          _coverBytes = bytes;
        }
      });
    } else {
      setState(() {
        if (isLogo) {
          _logoXFile = picked;
          _logoBytes = null;
        } else {
          _coverXFile = picked;
          _coverBytes = null;
        }
      });
    }
  }

  Future<String?> _uploadToApi({required bool isLogo}) async {
    final xfile = isLogo ? _logoXFile : _coverXFile;
    final bytes = isLogo ? _logoBytes : _coverBytes;
    if (xfile == null) {
      return isLogo ? _initialLogoUrl : _initialImageUrl; // no cambió
    }

    return _adminService.uploadImageToApi(
      xfile,
      isLogo ? 'restaurants/logo' : 'restaurants/profile',
      webBytes: kIsWeb ? bytes : null,
    );
  }

  Future<void> _selectTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
      helpText:
          isOpening
              ? 'Selecciona hora de apertura'
              : 'Selecciona hora de cierre',
      builder:
          (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child ?? const SizedBox.shrink(),
          ),
    );
    if (picked != null) {
      setState(() => isOpening ? _openingTime = picked : _closingTime = picked);
    }
  }

  Future<void> _onSubmit() async {
    final creating = !widget.isEdit;

    // Validaciones mínimas
    if (!_formKey.currentState!.validate()) return;
    if (creating &&
        _coverXFile == null &&
        (_initialImageUrl?.isEmpty ?? true)) {
      _showSnack('Selecciona una imagen de portada.');
      return;
    }
    if (creating && _logoXFile == null && (_initialLogoUrl?.isEmpty ?? true)) {
      _showSnack('Selecciona un logo.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Confirmar'),
            content: Text(
              creating
                  ? '¿Crear este restaurante?'
                  : '¿Actualizar este restaurante?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(creating ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // Subidas (solo si cambiaron)
      String? imageUrl = await _uploadToApi(isLogo: false);
      String? logoUrl = await _uploadToApi(isLogo: true);

      if (imageUrl == null || logoUrl == null) {
        throw Exception('No se pudo subir la imagen o el logo.');
      }

      // Normaliza el nombre: minúsculas y sin tildes
      String normalizeName(String name) {
        final withLower = name.toLowerCase();
        const accents = 'áéíóúüñ';
        const replacements = 'aeiounn';
        String result = '';
        for (int i = 0; i < withLower.length; i++) {
          final idx = accents.indexOf(withLower[i]);
          if (idx != -1) {
            result += replacements[idx];
          } else {
            result += withLower[i];
          }
        }
        return result;
      }

      final now = DateTime.now();
      final selectedDays =
          _daysOfWeek
              .asMap()
              .entries
              .where((e) => _selectedDays[e.key])
              .map((e) => e.value)
              .toList();

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'openDays': selectedDays,
        // Guardar en 24h para evitar dependencias de locale
        'openHours': {
          'opening': _timeTo24h(_openingTime),
          'closing': _timeTo24h(_closingTime),
        },
        'googleMapsUrl': _locationUrlController.text.trim(),
        'managerId': widget.isEdit ? widget.restaurant?.managerId : null,
        'imageUrl': imageUrl,
        'logoUrl': logoUrl,
        'idCategoriaFood': _selectedCategoryId ?? 'HliSwRHI71XR8VBlzXo6',
        'is_especial': _isEspecial,
        'normalizedName': normalizeName(_nameController.text.trim()),
        'updatedAt': Timestamp.fromDate(now),
      };

      if (creating) {
        data['createdAt'] = Timestamp.fromDate(now);
        await FirebaseFirestore.instance.collection('restaurants').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurant!.id)
            .update(data);
      }

      if (!mounted) return;
      _showSnack(creating ? 'Restaurante creado' : 'Restaurante actualizado');
      Navigator.of(context).pop(true);
    } catch (e, st) {
      // ignore: avoid_print
      print('[AddRestaurantScreen] Error: $e\n$st');
      _showSnack('Error al guardar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final creating = !widget.isEdit;
    final primary = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.second,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          creating ? 'Crear Restaurante' : 'Editar Restaurante',
          style: const TextStyle(
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Card(
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Colors.black12,
                          width: 1.2,
                        ),
                      ),
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionTitle('Imágenes'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  ImagePickerTile(
                                    title: 'Imagen del restaurante',
                                    placeholder: 'Selecciona una imagen',
                                    onPick: () => _pickImage(isLogo: false),
                                    networkUrl: _initialImageUrl,
                                    xfile: _coverXFile,
                                    webBytes: _coverBytes,
                                    height: 170,
                                    width: 340,
                                    color: primary,
                                  ),
                                  ImagePickerTile(
                                    title: 'Logo',
                                    placeholder: 'Selecciona un logo',
                                    onPick: () => _pickImage(isLogo: true),
                                    networkUrl: _initialLogoUrl,
                                    xfile: _logoXFile,
                                    webBytes: _logoBytes,
                                    height: 120,
                                    width: 120,
                                    isCircle: true,
                                    color: primary,
                                  ),
                                ],
                              ),

                              // Checkbox para marcar si es especial
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _isEspecial,
                                      onChanged: (val) {
                                        setState(() {
                                          _isEspecial = val ?? false;
                                        });
                                      },
                                    ),
                                    const Text(
                                      '¿Es restaurante especial?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                              const SectionTitle('Datos generales'),
                              const SizedBox(height: 12),
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _getCategorieFood(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text(
                                      'Error al cargar categorías: \\${snapshot.error}',
                                    );
                                  }
                                  final categories = snapshot.data ?? [];
                                  return LabeledField(
                                    label: 'Categoría de comida',
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      items:
                                          categories
                                              .map<DropdownMenuItem<String>>(
                                                (cat) =>
                                                    DropdownMenuItem<String>(
                                                      value: cat['id'],
                                                      child: Text(
                                                        cat['category'] ?? '',
                                                      ),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => _selectedCategoryId = val,
                                          ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Selecciona una categoría',
                                      ),
                                      validator:
                                          (v) =>
                                              (v == null || v.isEmpty)
                                                  ? 'Selecciona una categoría'
                                                  : null,
                                    ),
                                  );
                                },
                              ),

                              LabeledField(
                                label: 'Nombre',
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ej. Koko Restaurant',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.black87),
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Campo requerido'
                                              : null,
                                ),
                              ),
                              const SizedBox(height: 12),

                              LabeledField(
                                label: 'Descripción',
                                child: TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Breve descripción del restaurante',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.black87),
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Campo requerido'
                                              : null,
                                ),
                              ),
                              const SizedBox(height: 12),

                              LabeledField(
                                label: 'Ubicación (dirección)',
                                child: TextFormField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ej. Av. Siempre Viva 742',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.black87),
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Campo requerido'
                                              : null,
                                ),
                              ),

                              LabeledField(
                                label: 'URL de Google Maps',
                                trailing: IconButton(
                                  tooltip: 'Pegar desde portapapeles',
                                  onPressed: () async {},
                                  icon: const Icon(
                                    Icons.paste,
                                    color: Colors.black54,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _locationUrlController,
                                  decoration: const InputDecoration(
                                    hintText: 'https://maps.google.com/...',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.black87),
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Campo requerido'
                                              : null,
                                ),
                              ),

                              const SizedBox(height: 24),
                              const SectionTitle('Días y horarios'),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectTime(true),
                                      icon: const Icon(
                                        Icons.schedule,
                                        color: Colors.black87,
                                      ),
                                      label: Text(
                                        'Abre: ${_timeTo24h(_openingTime)}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: primary,
                                          width: 1,
                                        ),
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _selectTime(false),
                                      icon: const Icon(
                                        Icons.schedule_outlined,
                                        color: Colors.black87,
                                      ),
                                      label: Text(
                                        'Cierra: ${_timeTo24h(_closingTime)}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: primary,
                                          width: 1,
                                        ),
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_daysOfWeek.length, (
                                  i,
                                ) {
                                  final selected = _selectedDays[i];
                                  return FilterChip(
                                    label: Text(
                                      _daysOfWeek[i],
                                      style: TextStyle(
                                        color:
                                            selected ? primary : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    selected: selected,
                                    onSelected:
                                        (v) => setState(
                                          () => _selectedDays[i] = v,
                                        ),
                                    selectedColor: primary.withOpacity(0.12),
                                    backgroundColor: Colors.white,
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color:
                                            selected ? primary : Colors.black26,
                                      ),
                                    ),
                                    showCheckmark: false,
                                  );
                                }),
                              ),

                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).maybePop(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.black87,
                                      ),
                                      label: const Text(
                                        'Cancelar',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.black26,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _onSubmit,
                                      icon: Icon(
                                        creating
                                            ? Icons.save
                                            : Icons.check_circle,
                                      ),
                                      label: Text(
                                        creating ? 'Guardar' : 'Actualizar',
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
