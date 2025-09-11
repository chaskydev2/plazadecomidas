import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/core/services/s3_upload_service.dart';

import '../../cliente/models/menu_item.dart' as client_models;
import '../services/menu_service.dart';
import '../services/category_service.dart';
import '../services/variation_service.dart';

class MenuItemFormScreen extends StatefulWidget {
  final String restaurantId;
  final client_models.MenuItem? item;

  const MenuItemFormScreen({Key? key, required this.restaurantId, this.item})
    : super(key: key);

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuService = MenuService();
  final _categoryService = CategoryService();
  final _variationService = VariationService();
  // final S3UploadService _s3Service = S3UploadService();

  /// Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _variationNameController = TextEditingController();
  final _variationPriceController = TextEditingController();
  final _categoryController = TextEditingController();

  /// Image state
  XFile? _selectedImage;
  Uint8List? _webImage;
  String? _previewImageUrl;

  /// Data state
  List<client_models.Variation> _variations = [];
  List<String> _categories = [];
  List<String> _availableCategories = [];
  List<client_models.Variation> _availableVariations = [];

  bool _isDefaultVariation = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.item != null) _initializeFormWithItem(widget.item!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _variationNameController.dispose();
    _variationPriceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _initializeFormWithItem(client_models.MenuItem item) {
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _priceController.text = item.price.toStringAsFixed(2);
    _previewImageUrl = item.imageUrl;
    _variations = List.from(item.variations);
    _categories = List.from(item.categories);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Categorías disponibles
    _categoryService.getCategories(widget.restaurantId).listen((categories) {
      if (!mounted) return;
      setState(() => _availableCategories = categories);
    });

    // Variaciones disponibles
    _variationService.getVariationTemplates(widget.restaurantId).listen((vars) {
      if (!mounted) return;
      setState(() => _availableVariations = vars);
    });

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      if (!mounted) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _webImage = bytes;
          _previewImageUrl = null; // forzar vista local
        });
      } else {
        setState(() {
          _selectedImage = image;
          _webImage = null;
          _previewImageUrl = null; // forzar vista local
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  void _setLoading(bool loading, {String? message}) {
    if (!mounted) return;
    setState(() {
      _isLoading = loading;
      _loadingMessage = message;
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(
      true,
      message: widget.item == null ? 'Creando plato…' : 'Guardando cambios…',
    );

    try {
      String? imageUrl = _previewImageUrl;
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price =
          double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ??
          0.0;

      // Subida de imagen si hay nueva selección
      if (_selectedImage != null) {
        // Siempre al folder "item"
        final uploadedUrl = await _menuService.uploadImageToApi(
          _selectedImage!,
          'item',
          webBytes: _webImage, // En web enviamos bytes
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception('No se recibió URL de imagen desde el API.');
        }
      }

      if (widget.item == null) {
        final newItem = client_models.MenuItem(
          id: '',
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl ?? '',
          restaurantId: widget.restaurantId,
          isAvailable: true,
          variations: _variations,
          categories: _categories,
        );
        await _menuService.addMenuItem(newItem);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plato agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final updatedItem = widget.item!.copyWith(
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl ?? widget.item!.imageUrl,
          variations: _variations,
          categories: _categories,
        );
        await _menuService.updateMenuItem(updatedItem);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plato actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error al guardar el plato: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _addVariation() {
    final name = _variationNameController.text.trim();
    if (name.isEmpty) return;
    final price =
        double.tryParse(
          _variationPriceController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    final variation = client_models.Variation(
      name: name,
      price: price,
      isDefault: _isDefaultVariation,
    );

    setState(() {
      if (_isDefaultVariation) {
        // Asegurarse que solo una sea predeterminada
        _variations =
            _variations.map((v) => v.copyWith(isDefault: false)).toList();
      }
      _variations.add(variation);
      _variationNameController.clear();
      _variationPriceController.clear();
      _isDefaultVariation = false;
    });
  }

  void _addExistingVariation(client_models.Variation v) {
    final exists = _variations.any((e) => e.name == v.name);
    if (exists) return;
    setState(() => _variations.add(v));
  }

  void _removeVariation(int index) {
    setState(() => _variations.removeAt(index));
  }

  void _toggleDefault(int index) {
    setState(() {
      _variations =
          _variations.asMap().entries.map((e) {
            final isDefault = e.key == index;
            return e.value.copyWith(isDefault: isDefault);
          }).toList();
    });
  }

  void _addCategory() {
    final category = _categoryController.text.trim();
    if (category.isEmpty) return;
    if (_categories.contains(category)) return;

    setState(() {
      _categories.add(category);
      _categoryController.clear();
    });

    _categoryService.addCategory(widget.restaurantId, category);
  }

  void _removeCategory(String category) {
    setState(() => _categories.remove(category));
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Agregar Plato' : 'Editar Plato'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ——— Imagen
                  SectionCard(
                    title: 'Foto del plato',
                    accent: accent,
                    child: InkWell(
                      onTap: _isLoading ? null : _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: accent, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                    footer: TextButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Seleccionar imagen'),
                    ),
                  ),

                  // ——— Datos básicos
                  SectionCard(
                    title: 'Datos del plato',
                    accent: accent,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          decoration: _dec(
                            label: 'Nombre del Plato',
                            prefix: const Icon(Icons.ramen_dining_outlined),
                          ),
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Este campo es requerido'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isLoading,
                          maxLines: 3,
                          decoration: _dec(
                            label: 'Descripción (opcional)',
                            prefix: const Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          enabled: !_isLoading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: _dec(
                            label: 'Precio Base (Bs)',
                            prefix: const Icon(Icons.price_change_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Por favor ingresa un precio';
                            final p = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (p == null || p <= 0)
                              return 'Por favor ingresa un precio válido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  // ——— Variaciones
                  SectionCard(
                    title: 'Variaciones (opcional)',
                    accent: accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_availableVariations.isNotEmpty) ...[
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (c, i) {
                                final v = _availableVariations[i];
                                final already = _variations.any(
                                  (e) => e.name == v.name,
                                );
                                return FilterChip(
                                  label: Text(
                                    '${v.name} (Bs. ${v.price.toStringAsFixed(2)})',
                                  ),
                                  selected: already,
                                  onSelected: (_) => _addExistingVariation(v),
                                );
                              },
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemCount: _availableVariations.length,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_variations.isNotEmpty) ...[
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _variations.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = _variations.removeAt(oldIndex);
                                _variations.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final v = _variations[index];
                              return Card(
                                key: ValueKey('v-$index-${v.name}'),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Radio<int>(
                                    value: index,
                                    groupValue: _variations.indexWhere(
                                      (e) => e.isDefault,
                                    ),
                                    onChanged: (_) => _toggleDefault(index),
                                  ),
                                  title: Text(
                                    '${v.name} · Bs. ${v.price.toStringAsFixed(2)}',
                                  ),
                                  subtitle:
                                      v.isDefault
                                          ? const Text('Predeterminado')
                                          : null,
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.primary,
                                    ),
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => _removeVariation(index),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _variationNameController,
                                enabled: !_isLoading,
                                decoration: _dec(label: 'Nombre de variación'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _variationPriceController,
                                enabled: !_isLoading,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                decoration: _dec(
                                  label: 'Precio',
                                  prefix: const Icon(Icons.payments_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: accent),
                                  tooltip: 'Añadir variación',
                                  onPressed: _isLoading ? null : _addVariation,
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isDefaultVariation,
                                      onChanged:
                                          _isLoading
                                              ? null
                                              : (v) => setState(
                                                () =>
                                                    _isDefaultVariation =
                                                        v ?? false,
                                              ),
                                      activeColor: accent,
                                    ),
                                    const Text('Predeterminada'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ——— Categorías
                  SectionCard(
                    title: 'Categorías',
                    accent: accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips seleccionadas
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _categories
                                  .map(
                                    (c) => Chip(
                                      label: Text(c),
                                      backgroundColor: accent.withOpacity(.12),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onDeleted:
                                          _isLoading
                                              ? null
                                              : () => _removeCategory(c),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 12),
                        // Autocomplete + añadir
                        Row(
                          children: [
                            Expanded(
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue v) {
                                  if (v.text.isEmpty)
                                    return const Iterable<String>.empty();
                                  return _availableCategories.where(
                                    (o) => o.toLowerCase().contains(
                                      v.text.toLowerCase(),
                                    ),
                                  );
                                },
                                onSelected: (value) {
                                  _categoryController.text = value;
                                },
                                fieldViewBuilder: (
                                  ctx,
                                  controller,
                                  focus,
                                  onSubmit,
                                ) {
                                  return TextField(
                                    controller:
                                        controller
                                          ..text = _categoryController.text,
                                    focusNode: focus,
                                    enabled: !_isLoading,
                                    onChanged:
                                        (t) => _categoryController.text = t,
                                    decoration: _dec(
                                      label: 'Nueva categoría',
                                      hint: 'Escribe y presiona Añadir',
                                    ),
                                    onSubmitted: (_) => _addCategory(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addCategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Añadir',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ——— Guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.item == null
                            ? 'Agregar Plato'
                            : 'Guardar Cambios',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay de carga
          if (_isLoading && _loadingMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(.20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _loadingMessage!,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ——— UI Helpers
  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      if (kIsWeb && _webImage != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_webImage!, fit: BoxFit.cover),
            _imageOverlay(),
          ],
        );
      } else if (!kIsWeb) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
            _imageOverlay(),
          ],
        );
      }
    }

    if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _previewImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder:
                (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
          ),
          _imageOverlay(),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFFD91010)),
          SizedBox(height: 8),
          Text(
            'Toca para agregar una foto',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _imageOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(.25), Colors.transparent],
        ),
      ),
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_in, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('Vista previa', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Pequeño contenedor estético para secciones
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final Color accent;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [accent.withOpacity(.06), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Align(alignment: Alignment.centerRight, child: footer!),
            ),
        ],
      ),
    );
  }
}
