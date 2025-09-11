// lib/core/models/branch.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id; // documentId
  final String nombre; // "test centro"
  final String direccion; // "centro123"
  final String imgUrl; // ""
  final double? lat; // 123231  (o GeoPoint)
  final double? lng; // 12321313
  final String restaurantId; // "HciapvUGrsVKtfrf6WoK"
  final DateTime? createdAt; // Timestamp
  final DateTime? updatedAt; // Timestamp

  const Branch({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.imgUrl,
    required this.restaurantId,
    this.lat,
    this.lng,
    this.createdAt,
    this.updatedAt,
  });

  Branch copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? imgUrl,
    double? lat,
    double? lng,
    String? restaurantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      imgUrl: imgUrl ?? this.imgUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      restaurantId: restaurantId ?? this.restaurantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Crea el modelo desde un DocumentSnapshot
  factory Branch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final latLng = _readLatLng(data);

    return Branch(
      id: doc.id,
      nombre: (data['nombre'] ?? '') as String,
      direccion: (data['direccion'] ?? '') as String,
      imgUrl: (data['imgUrl'] ?? '') as String,
      lat: latLng.$1,
      lng: latLng.$2,
      restaurantId: (data['restaurantId'] ?? '') as String,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  /// Mapa listo para guardar en Firestore
  Map<String, dynamic> toFirestore({bool includeTimestamps = true}) {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'imgUrl': imgUrl,
      'restaurantId': restaurantId,
      // guarda lat/lng como números (si existen)
      if (lat != null) 'lat': lat,
      if (lng != null) 'long': lng, // tu colección usa "long"
      if (includeTimestamps)
        'createdAt':
            createdAt != null
                ? Timestamp.fromDate(createdAt!)
                : FieldValue.serverTimestamp(),
      if (includeTimestamps)
        'updatedAt':
            updatedAt != null
                ? Timestamp.fromDate(updatedAt!)
                : FieldValue.serverTimestamp(),
    };
  }

  // ---- Helpers ----

  static (double?, double?) _readLatLng(Map<String, dynamic> data) {
    // Soporta:
    // - 'lat' y 'long'
    // - posible typo 'lant' en lugar de 'lat'
    // - GeoPoint en 'location'
    if (data['location'] is GeoPoint) {
      final g = data['location'] as GeoPoint;
      return (g.latitude, g.longitude);
    }

    double? lat;
    double? lng;

    // 'lat' o 'lant'
    final latRaw = data.containsKey('lat') ? data['lat'] : data['lant'];
    if (latRaw is num) lat = latRaw.toDouble();

    // 'long'
    final lngRaw = data['long'];
    if (lngRaw is num) lng = lngRaw.toDouble();

    return (lat, lng);
  }

  static DateTime? _readDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
