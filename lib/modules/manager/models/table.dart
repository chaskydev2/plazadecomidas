import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantTable {
  final String id;
  final int number;
  final bool isOccupied;
  final String restaurantId;
  final String qrCode;
  final DateTime? lastOccupiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RestaurantTable({
    required this.id,
    required this.number,
    this.isOccupied = false,
    required this.restaurantId,
    required this.qrCode,
    this.lastOccupiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] as String,
      number: (json['number'] as num).toInt(),
      isOccupied: json['isOccupied'] as bool? ?? false,
      restaurantId: json['restaurantId'] as String,
      qrCode: json['qrCode'] as String,
      lastOccupiedAt: json['lastOccupiedAt'] != null 
          ? (json['lastOccupiedAt'] as Timestamp).toDate() 
          : null,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'isOccupied': isOccupied,
      'restaurantId': restaurantId,
      'qrCode': qrCode,
      'lastOccupiedAt': lastOccupiedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    }..removeWhere((key, value) => value == null);
  }

  // Crear una nueva mesa en la subcolección del restaurante
  static Future<RestaurantTable> create({
    required int number,
    required String restaurantId,
    required String qrCode,
  }) async {
    try {
      // Primero, verificar si el restaurante existe
      final restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
      final restaurantDoc = await restaurantRef.get();
      
      if (!restaurantDoc.exists) {
        throw Exception('El restaurante especificado no existe');
      }

      // Verificar si ya existe una mesa con el mismo número
      final existingTable = await restaurantRef
          .collection('tables')
          .where('number', isEqualTo: number)
          .limit(1)
          .get();

      if (existingTable.docs.isNotEmpty) {
        throw Exception('Ya existe una mesa con el número $number');
      }

      // Verificar si ya existe una mesa con el mismo QR
      final existingQR = await FirebaseFirestore.instance
          .collectionGroup('tables')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (existingQR.docs.isNotEmpty) {
        throw Exception('El código QR ya está en uso por otra mesa');
      }

      // Crear la referencia al documento de la mesa
      final tableRef = restaurantRef.collection('tables').doc();
      final now = DateTime.now();
      
      // Crear el objeto de la mesa
      final newTable = RestaurantTable(
        id: tableRef.id,
        number: number,
        restaurantId: restaurantId,
        qrCode: qrCode,
        isOccupied: false,
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en Firestore
      await tableRef.set(newTable.toJson());
      
      print('Mesa creada exitosamente en: restaurants/$restaurantId/tables/${tableRef.id}');
      
      return newTable;
    } catch (e) {
      print('Error al crear la mesa: $e');
      rethrow;
    }
  }

  // Actualizar estado de ocupación
  Future<void> updateOccupancy(bool occupied) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .doc(id)
        .update({
          'isOccupied': occupied,
          'lastOccupiedAt': occupied ? DateTime.now() : lastOccupiedAt,
          'updatedAt': DateTime.now(),
        });
  }

  // Obtener una mesa por ID
  static Future<RestaurantTable?> getById(String restaurantId, String tableId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .get();

      if (!doc.exists) return null;

      return RestaurantTable.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      print('Error al obtener la mesa: $e');
      return null;
    }
  }

  // Obtener stream de todas las mesas de un restaurante
  static Stream<List<RestaurantTable>> streamTables(String restaurantId) {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .orderBy('number')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RestaurantTable.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  // Eliminar una mesa
  static Future<void> delete(String restaurantId, String tableId) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .doc(tableId)
        .delete();
  }

  // Actualizar datos de la mesa
  Future<void> update({
    int? number,
    String? qrCode,
  }) async {
    final updates = <String, dynamic>{
      if (number != null) 'number': number,
      if (qrCode != null) 'qrCode': qrCode,
      'updatedAt': DateTime.now(),
    };

    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .doc(id)
        .update(updates);
  }

  RestaurantTable copyWith({
    String? id,
    int? number,
    bool? isOccupied,
    String? restaurantId,
    String? qrCode,
    DateTime? lastOccupiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      number: number ?? this.number,
      isOccupied: isOccupied ?? this.isOccupied,
      restaurantId: restaurantId ?? this.restaurantId,
      qrCode: qrCode ?? this.qrCode,
      lastOccupiedAt: lastOccupiedAt ?? this.lastOccupiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}