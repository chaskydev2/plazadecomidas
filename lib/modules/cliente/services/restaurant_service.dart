import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/cliente/models/menu_item.dart';

class RestaurantService {
  /// Busca restaurantes especiales por categoría y nombre combinados
  Stream<List<Restaurant>> searchEspecialRestaurantsByCategoryAndName1(
    String categoryId,
    String query,
  ) {
    final normalizedQuery = _normalizeText(query);
    print(
      "Buscando restaurantes especiales en la categoría $categoryId con la consulta: $normalizedQuery",
    );
    return _firestore
        .collection(_collection)
        .where('is_especial', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('normalizedName')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Restaurant.fromFirestore(doc))
                  .toList(),
        );
  }

  Stream<List<Restaurant>> searchEspecialRestaurantsByCategoryAndName(
    String categoryId,
    String query,
  ) {
    final q = _normalizeText(query).trim();
    print("Buscando restaurantes en la categoría con la consulta: $query");
    // Si no hay texto, puedes devolver sólo por categoría + especial
    // (esto puede requerir índice compuesto; si no lo tienes, filtra en memoria)
    if (q.isEmpty) {
      return _firestore
          .collection(_collection)
          .where('is_especial', isEqualTo: true)
          .snapshots()
          .map(
            (s) =>
                s.docs
                    .map((d) => Restaurant.fromFirestore(d))
                    .where((r) => r.idCategoriaFood == categoryId)
                    .toList(),
          );
    }

    // 🔎 Buscar por nombre (índice de un solo campo) y luego filtrar en memoria
    return _firestore
        .collection(_collection)
        .orderBy('normalizedName')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(50)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => Restaurant.fromFirestore(d))
                  .where(
                    (r) =>
                        r.isEspecial == true && r.idCategoriaFood == categoryId,
                  )
                  .toList(),
        );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'restaurants';

  /// Busca restaurantes por categoría y nombre combinados
  Stream<List<Restaurant>> searchRestaurantsByCategoryAndName(
    String categoryId,
    String query,
  ) {
    print("Buscando restaurantes en la categoría con la consulta: $query");
    final normalizedQuery = _normalizeText(query);
    return _firestore
        .collection(_collection)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('normalizedName')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Restaurant.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Obtiene solo los restaurantes especiales (is_especial == true)
  Stream<List<Restaurant>> getEspecialRestaurants() {
    return _firestore
        .collection(_collection)
        .where('is_especial', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Restaurant.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> updateRestaurantsWithNormalizedName() async {
    final snapshot = await _firestore.collection(_collection).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final name = doc.data()['name'] as String;
      batch.update(doc.reference, {'normalizedName': _normalizeText(name)});
    }

    await batch.commit();
  }

  Stream<List<Restaurant>> getRestaurants() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) {
                    try {
                      return Restaurant.fromFirestore(doc);
                    } catch (e) {
                      print('Error al procesar restaurante ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((restaurant) => restaurant != null)
                  .map((restaurant) => restaurant!)
                  .toList(),
        );
  }

  Future<Restaurant?> getRestaurant(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Restaurant.fromJson({'id': doc.id, ...doc.data()!}, id: '');
    } catch (e) {
      print('Error al obtener restaurante: $e');
      return null;
    }
  }

  Future<void> updateSearchKeywords(String restaurantId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(restaurantId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final name = data['name'] as String;
      final keywords = generateSearchKeywords(name);

      await _firestore.collection(_collection).doc(restaurantId).update({
        'searchKeywords': keywords,
        'normalizedName': _normalizeText(name),
      });
    } catch (e) {
      print('Error updating search keywords: $e');
    }
  }

  // Método optimizado para búsqueda
  // Método optimizado para búsqueda de restaurantes especiales
  Stream<List<Restaurant>> searchEspecialRestaurants(String query) {
    if (query.isEmpty) {
      return getEspecialRestaurants();
    }

    final normalizedQuery = _normalizeText(query);

    return _firestore
        .collection(_collection)
        .where('is_especial', isEqualTo: true)
        .orderBy('normalizedName')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .snapshots()
        .handleError((error) {
          print('Error en búsqueda: $error');
          return [];
        })
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Restaurant.fromFirestore(doc))
                  .toList(),
        );
  }

  // Método optimizado para búsqueda general
  Stream<List<Restaurant>> searchRestaurants(String query) {
    if (query.isEmpty) return getRestaurants();

    final normalizedQuery = _normalizeText(query);

    return _firestore
        .collection(_collection)
        .orderBy('normalizedName')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .snapshots()
        .handleError((error) {
          print('Error en búsqueda: $error');
          return [];
        })
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Restaurant.fromFirestore(doc))
                  .toList(),
        );
  }

  //Future<List<MenuItem>> getMenuForTable(String tableId, String restaurantId) async {

  /*
    try {
      // Verificar que la mesa existe
      final table = await RestaurantTable.getById(restaurantId, tableId);
      if (table == null) {
        throw Exception('No se encontró la mesa especificada');
      }

      // Obtener el menú del restaurante
      final menuSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_items')
          .where('isAvailable', isEqualTo: true)
          .get();

      return menuSnapshot.docs
          .map((doc) => MenuItem.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      print('Error al obtener el menú: $e');
      rethrow;
    }
  }

  */

  /// Obtiene los items del menú de un restaurante por su ID
  Future<List<MenuItem>> getMenuRestourant(String restaurantId) async {
    try {
      final menuSnapshot =
          await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('menu_items')
              .where('isAvailable', isEqualTo: true)
              .get();

      return menuSnapshot.docs
          .map((doc) => MenuItem.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error al obtener el menú: $e');
      rethrow;
    }
  }

  Future<List<Restaurant>> getEspecialRestaurantsByName(String query) async {
    print("Buscando restaurantes especiales con la consulta: $query");
    final querySnapshot =
        await _firestore
            .collection('restaurants')
            .where('is_especial', isEqualTo: true)
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z')
            .get(); // Usamos get() en lugar de snapshots()

    return querySnapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc))
        .toList();
  }

  List<String> generateSearchKeywords(String text) {
    if (text.isEmpty) return [];

    // 1. Normalizar el texto (minúsculas, sin acentos)
    final normalizedText = _normalizeText(text);

    // 2. Dividir en palabras individuales
    final words = normalizedText.split(' ');

    // 3. Generar prefijos para cada palabra
    final keywords = <String>[];

    for (final word in words.where((w) => w.isNotEmpty)) {
      // Generar todos los prefijos posibles (p, pi, piz, pizz...)
      for (int i = 1; i <= word.length; i++) {
        final prefix = word.substring(0, i);
        if (!keywords.contains(prefix)) {
          keywords.add(prefix);
        }
      }

      // Añadir la palabra completa si no está ya
      if (!keywords.contains(word)) {
        keywords.add(word);
      }
    }

    // 4. Generar combinaciones de palabras (solo si hay múltiples palabras)
    if (words.length > 1) {
      // Añadir el texto completo normalizado
      final fullText = words.join(' ');
      if (!keywords.contains(fullText)) {
        keywords.add(fullText);
      }

      // Generar algunas combinaciones comunes (opcional)
      if (words.length == 2) {
        final combined = words.last + words.first; // Ej: "napolipizzería"
        if (!keywords.contains(combined)) {
          keywords.add(combined);
        }
      }
    }

    // 5. Ordenar por longitud para mejor organización
    keywords.sort((a, b) => a.length.compareTo(b.length));

    return keywords;
  }

  String _normalizeText(String text) {
    //    print("Normalizando texto: $text");
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }
}
