import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  // Core
  final String id;
  final String name;
  final String email;

  // Perfil
  final String? phone; // lee 'phone' o 'phoneNumber'
  final String? address;
  final String? photoUrl; // URL pública de Storage
  final String? photoStoragePath; // ruta interna en Storage
  final List<String> preferences;

  // App / negocio
  final String? restaurantId;
  final String? branchId;
  final String? role;
  final bool notifications;
  final bool active;

  // Tiempos
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.photoStoragePath,
    this.preferences = const [],
    this.restaurantId,
    this.branchId,
    this.role,
    this.notifications = true,
    this.active = true,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  /// Crea desde un Map (por ejemplo, {'id': ..., ...})
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Validaciones mínimas - solo id y email son realmente obligatorios
    if (json['id'] == null || json['email'] == null) {
      throw Exception('Datos del perfil incompletos: falta id o email');
    }

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Usuario',
      email: json['email'] as String,
      // Soporta 'phone' y 'phoneNumber'
      phone: (json['phone'] ?? json['phoneNumber']) as String?,
      address: json['address'] as String?,
      photoUrl: json['photoUrl'] as String?,
      photoStoragePath: json['photoStoragePath'] as String?,
      preferences:
          json['preferences'] is Iterable
              ? List<String>.from(json['preferences'])
              : const [],
      restaurantId: json['restaurantId'] as String?,
      branchId: json['branchId'] as String?,
      role: json['role'] as String?,
      notifications: (json['notifications'] as bool?) ?? true,
      active: (json['active'] as bool?) ?? true,
      createdAt: _toDateTimeOrNull(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTimeOrNull(json['updatedAt']),
      lastLogin: _toDateTimeOrNull(json['lastLogin']),
    );
  }

  /// Crea desde un DocumentSnapshot de Firestore
  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento de usuario vacío (${doc.id})');
    }
    return UserProfile.fromJson({'id': doc.id, ...data});
  }

  /// Serializa a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      // Guardamos como 'phoneNumber' para unificar
      if (phone != null) 'phoneNumber': phone,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoStoragePath != null) 'photoStoragePath': photoStoragePath,
      if (preferences.isNotEmpty) 'preferences': preferences,
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (branchId != null) 'branchId': branchId,
      if (role != null) 'role': role,
      'notifications': notifications,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }

  /// copyWith para crear una copia modificada de forma segura
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
    String? photoStoragePath,
    List<String>? preferences,
    String? restaurantId,
    String? branchId,
    String? role,
    bool? notifications,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStoragePath: photoStoragePath ?? this.photoStoragePath,
      preferences: preferences ?? this.preferences,
      restaurantId: restaurantId ?? this.restaurantId,
      branchId: branchId ?? this.branchId,
      role: role ?? this.role,
      notifications: notifications ?? this.notifications,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// Iniciales útiles para UI (avatar)
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final take2 = parts.take(2).map((s) => s[0].toUpperCase()).join();
    return take2.isEmpty ? 'U' : take2;
  }

  // ===== Helpers para fechas =====
  static DateTime _toDateTime(dynamic v) {
    if (v == null) {
      throw Exception('createdAt es null');
    }
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.parse(v.toString());
  }

  static DateTime? _toDateTimeOrNull(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
