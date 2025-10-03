// lib/modules/cliente/screens/profile_screen.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kokorestaurant/modules/cliente/models/user_profile.dart';
import 'package:kokorestaurant/modules/cliente/services/user_service.dart';
import 'package:kokorestaurant/modules/cliente/screens/account_settings_screen.dart'
    as AppTheme;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _userService = UserService();

  UserProfile? _userProfile;

  // Imagen seleccionada
  XFile? _pickedXFile; // fuente para subir (móvil/web)
  File? _pickedFileMobile; // preview en móvil

  String? _editedName;
  String? _editedEmail;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) _load(u.uid);
  }

  Future<void> _load(String uid) async {
    try {
      final p = await _userService.getUserProfile(uid);
      if (!mounted) return;
      setState(() => _userProfile = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) {
      setState(() {
        _pickedXFile = x;
        if (!kIsWeb) _pickedFileMobile = File(x.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) return;

    setState(() => _isSaving = true);
    try {
      String? newPhotoUrl;

      // 1) Subir avatar si se seleccionó
      if (_pickedXFile != null) {
        newPhotoUrl = await _userService.saveAvatar(
          user.uid,
          _pickedXFile!,
          // headers: {'Authorization': 'Bearer ...'}, // si tu API lo requiere
        );
      }

      // 2) Actualizar nombre/email (+ photoUrl si corresponde)
      await _userService.updateUserProfile(user.uid, {
        'name': _editedName ?? _userProfile!.name,
        'email': _editedEmail ?? _userProfile!.email,
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
      });

      // 3) Refrescar perfil
      await _load(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (_userProfile?.photoUrl?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Editar Perfil'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ---- Avatar ----
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _pickedFileMobile != null
                                ? FileImage(_pickedFileMobile!)
                                : (hasPhoto
                                    ? NetworkImage(_userProfile!.photoUrl!)
                                    : null) as ImageProvider<Object>?,
                            child: (_pickedFileMobile == null && !hasPhoto)
                                ? const Icon(Icons.person, size: 55, color: Colors.black87)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const Icon(Icons.edit, size: 18, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ---- Nombre ----
                    TextFormField(
                      initialValue: _userProfile!.name,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        labelText: 'Nombre de Usuario',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (v) => _editedName = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingrese su nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    // ---- Email ----
                    TextFormField(
                      initialValue: _userProfile!.email,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        labelText: 'Email o Numero de Teléfono',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (v) => _editedEmail = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingrese su email' : null,
                    ),
                    const SizedBox(height: 20),

                    // ---- Vinculado (decorativo) ----
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.account_circle, size: 24, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Google', style: TextStyle(fontSize: 16)),
                          Spacer(),
                          Icon(Icons.link, size: 20),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ---- Guardar ----
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
