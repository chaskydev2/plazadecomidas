class Restaurant {
  final String id; // Puedes usar un UUID si lo necesitas
  final DateTime createdAt;
  final String description;
  final String googleMapsUrl;
  final String? imageUrl;
  final bool isEspecial;
  final String location;
  final String? logoUrl;
  final String managerId;
  final String name;
  final List<String> openDays;
  final Map<String, String> openHours;
  final int stars;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.googleMapsUrl,
    this.imageUrl,
    required this.isEspecial,
    required this.location,
    this.logoUrl,
    required this.managerId,
    required this.name,
    required this.openDays,
    required this.openHours,
    required this.stars,
    required this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json, {required String id}) {
    return Restaurant(
      id: id,
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      googleMapsUrl: json['googleMapsUrl'],
      imageUrl: json['imageUrl'],
      isEspecial: json['is_especial'],
      location: json['location'],
      logoUrl: json['logoUrl'],
      managerId: json['managerId'],
      name: json['name'],
      openDays: List<String>.from(json['openDays']),
      openHours: Map<String, String>.from(json['openHours']),
      stars: json['stars'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'googleMapsUrl': googleMapsUrl,
      'imageUrl': imageUrl,
      'is_especial': isEspecial,
      'location': location,
      'logoUrl': logoUrl,
      'managerId': managerId,
      'name': name,
      'openDays': openDays,
      'openHours': openHours,
      'stars': stars,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
