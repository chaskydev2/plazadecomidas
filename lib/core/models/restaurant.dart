import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> openDays;
  final Map<String, String> openHours;
  final String googleMapsUrl;
  final String? managerId;
  final double rating;
  final bool isOpen;
  final String? imageUrl;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final String? locationUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double price;
  final String? idCategoriaFood;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.openDays,
    required this.openHours,
    required this.googleMapsUrl,
    this.managerId,
    this.rating = 0.0,
    this.isOpen = true,
    this.imageUrl,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.locationUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.price,
    this.idCategoriaFood,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json, {required String id}) {
    if (json['id'] == null ||
        json['name'] == null ||
        json['description'] == null ||
        json['location'] == null ||
        json['openDays'] == null ||
        json['openHours'] == null ||
        json['googleMapsUrl'] == null ||
        json['createdAt'] == null ||
        json['updatedAt'] == null ||
        json['price'] == null) {
      throw Exception('Datos del restaurante incompletos');
    }

    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      openDays: List<String>.from(json['openDays']),
      openHours: Map<String, String>.from(json['openHours']),
      googleMapsUrl: json['googleMapsUrl'],
      managerId: json['managerId'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      isOpen: json['isOpen'] ?? true,
      imageUrl: json['imageUrl'],
      logoUrl: json['logoUrl'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      locationUrl: json['locationUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      price: (json['price'] as num).toDouble(),
      idCategoriaFood: json['idCategoriaFood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'openDays': openDays,
      'openHours': openHours,
      'googleMapsUrl': googleMapsUrl,
      'managerId': managerId,
      'rating': rating,
      'isOpen': isOpen,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'locationUrl': locationUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'price': price,
      'idCategoriaFood': idCategoriaFood,
    };
  }

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      openDays: List<String>.from(data['openDays'] ?? []),
      openHours: Map<String, String>.from(data['openHours'] ?? {}),
      googleMapsUrl: data['googleMapsUrl'] ?? '',
      managerId: data['managerId'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: data['isOpen'] ?? true,
      imageUrl: data['imageUrl'],
      logoUrl: data['logoUrl'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      locationUrl: data['locationUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      idCategoriaFood: data['idCategoriaFood'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'openDays': openDays,
      'openHours': openHours,
      'googleMapsUrl': googleMapsUrl,
      'managerId': managerId,
      'rating': rating,
      'isOpen': isOpen,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'locationUrl': locationUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'price': price,
      'idCategoriaFood': idCategoriaFood,
    };
  }

  String get formattedOpenHours {
    return openHours.entries.map((e) => "${e.key}: ${e.value}").join(", ");
  }

  get stars => null;

  get isEspecial => null;

  get backgroundUrl => null;

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    List<String>? openDays,
    Map<String, String>? openHours,
    String? googleMapsUrl,
    String? managerId,
    double? rating,
    bool? isOpen,
    String? imageUrl,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? locationUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? price,
    String? idCategoriaFood,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      openDays: openDays ?? this.openDays,
      openHours: openHours ?? this.openHours,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      managerId: managerId ?? this.managerId,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      locationUrl: locationUrl ?? this.locationUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      price: price ?? this.price,
      idCategoriaFood: idCategoriaFood ?? this.idCategoriaFood,
    );
  }

  toMap() {}
}
