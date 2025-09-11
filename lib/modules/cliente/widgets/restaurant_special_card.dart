// File: widgets/restaurant_card.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart'; // Necesario para getTemporaryDirectory

class _FixedImage {
  final MemoryImage image;
  final int width;
  final int height;
  const _FixedImage(this.image, this.width, this.height);

  double get aspectRatio => width / height;
}

class RestaurantSpecialCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantSpecialCard({
    Key? key,
    required this.restaurant,
    required this.onTap,
  }) : super(key: key);

  // Helper to format open hours - now simplified to match image
  String formatOpenHours(Map<String, String> openHours) {
    if (openHours.isEmpty) return 'Horario no disponible';
    final opening = openHours['opening'] ?? '';
    final closing = openHours['closing'] ?? '';
    if (opening.isNotEmpty && closing.isNotEmpty) {
      return '$opening - $closing'; // e.g., "12:00 - 22:00"
    }
    return 'Horario no disponible';
  }

  BoxFit _pickBoxFit(double aspectRatio) {
    if (aspectRatio >= 1.6) return BoxFit.cover; // muy horizontal
    if (aspectRatio <= 0.7)
      return BoxFit
          .cover; // muy vertical (puedes cambiar a contain si quieres ver todo)
    return BoxFit.cover; // intermedias
  }

  Future<_FixedImage?> _loadAndFixImage(String url) async {
    try {
      final response = await NetworkAssetBundle(Uri.parse(url)).load(url);
      final bytes = response.buffer.asUint8List();

      // 1) Decodificar
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // 2) Corregir orientación EXIF (rotaciones + espejado)
      final oriented = img.bakeOrientation(decoded);

      // 3) Redimensionar suave si es enorme (para memoria/perform)
      const int maxSide = 2000; // puedes ajustar
      img.Image working = oriented;
      if (oriented.width > maxSide || oriented.height > maxSide) {
        working = img.copyResize(
          oriented,
          width: oriented.width > oriented.height ? maxSide : null,
          height: oriented.height >= oriented.width ? maxSide : null,
          interpolation: img.Interpolation.cubic,
        );
      }

      working = img.flipVertical(working);
      // 4) Mantener transparencia si existe → PNG, si no → JPG
      final hasAlpha = working.numChannels == 4 || working.numChannels == 2;
      final fixedBytes =
          hasAlpha
              ? Uint8List.fromList(img.encodePng(working, level: 6))
              : Uint8List.fromList(img.encodeJpg(working, quality: 88));

      return _FixedImage(
        MemoryImage(fixedBytes),
        working.width,
        working.height,
      );
    } catch (e) {
      debugPrint("Error cargando imagen: $e");
      return null;
    }
  }

  // Helper to format open days - keeping it concise
  String formatOpenDays(List<String> openDays) {
    if (openDays.isEmpty) return 'Días no disponibles';
    return openDays.join(', '); // e.g., "Lun, Mar, Mié"
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FixedImage?>(
      future:
          (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
              ? _loadAndFixImage(restaurant.imageUrl!)
              : Future.value(null),
      builder: (context, snapshot) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 280, // Keep width for horizontal scroll
            margin: const EdgeInsets.only(right: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              color: Colors.black, // fondo de seguridad bajo la imagen
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (snapshot.data != null)
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                    child: Image(
                      image: snapshot.data!.image,
                      fit: _pickBoxFit(snapshot.data!.aspectRatio),
                      filterQuality: FilterQuality.high,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                    ),
                  ),
                // ---- Todo tu contenido encima ----
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                restaurant.logoUrl != null &&
                                        restaurant.logoUrl!.isNotEmpty
                                    ? Image.network(
                                      restaurant.logoUrl!,
                                      height: 60, // Slightly smaller logo
                                      width: 100, // Slightly smaller logo
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 60,
                                                width: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                  size: 30, // Adjust icon size
                                                ),
                                              ),
                                    )
                                    : Container(
                                      height: 60,
                                      width: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: Colors.grey,
                                        size: 30, // Adjust icon size
                                      ),
                                    ),
                          ),
                          const SizedBox(width: 10), // Reduced space
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize:
                                  MainAxisSize.min, // Use min to fit content
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.yellow,
                                          size: 14, // Smaller star icon
                                        ),
                                        const SizedBox(width: 3), // Smaller gap
                                        Text(
                                          restaurant.stars?.toStringAsFixed(
                                                1,
                                              ) ??
                                              'N/A',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12, // Smaller font
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ), // Gap between rating and name
                                    Expanded(
                                      child: Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              16, // Slightly smaller name font
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign:
                                            TextAlign.end, // Align name to end
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4), // Small gap
                                // Display open hours first as per image
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time, // Time icon
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatOpenHours(restaurant.openHours),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12, // Smaller font
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                // SizedBox(height: 2), // Even smaller gap if needed
                                // This section will now house the "Días de Atención" and the horizontal list
                                if (restaurant
                                    .openDays
                                    .isNotEmpty) // Only show if there are days
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                    ), // Small top padding
                                    child: SizedBox(
                                      height:
                                          24, // Reduced height for the horizontal list
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: restaurant.openDays.length,
                                        itemBuilder: (context, index) {
                                          final day =
                                              restaurant.openDays[index];
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                            ), // Smaller margin between chips
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  8, // Smaller horizontal padding for chips
                                              vertical:
                                                  4, // Smaller vertical padding for chips
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    15,
                                                  ), // More rounded corners
                                            ),
                                            child: Text(
                                              day,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    10, // Smaller font for days
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8), // Gap before button
                                Align(
                                  // Align button to the right, similar to image
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: onTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            14, // Slightly less horizontal padding
                                        vertical:
                                            6, // Slightly less vertical padding
                                      ),
                                      minimumSize:
                                          Size.zero, // Allows smaller size
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // Shrink tap area
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Ver Menu', // Changed to "Ver Menu" as per image
                                      style: TextStyle(
                                        fontSize: 12, // Smaller font for button
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
