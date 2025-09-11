import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final List<String> preferences;
  final DateTime createdAt;

  UserProfile({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? address,
    String? photoUrl,
    List<String>? preferences,
    required DateTime createdAt,
  }) : id = id,
       name = name,
       email = email,
       phone = phone,
       address = address,
       photoUrl = photoUrl,
       preferences = preferences ?? const [],
       createdAt = createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null ||
        json['name'] == null ||
        json['email'] == null ||
        json['createdAt'] == null) {
      throw Exception('Datos del perfil incompletos');
    }

    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photoUrl'] as String?,
      preferences:
          json['preferences'] != null
              ? List<String>.from(json['preferences'])
              : const [],
      createdAt:
          json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'].toString()),
    );
  }

  copyWith({required String name, required String email}) {}
}
