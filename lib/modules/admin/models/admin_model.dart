import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;
  final DateTime lastLogin;

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AdminModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }
} 