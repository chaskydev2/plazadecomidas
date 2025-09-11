import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../modules/cliente/models/menu_item.dart' as client_models;
import 'menu_item_form_screen.dart';

class MenuItemDetailScreen extends StatelessWidget {
  final client_models.MenuItem item;

  const MenuItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Barra roja con título y botón de volver
          SliverAppBar(
            backgroundColor: const Color(0xFFD91010),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Detalles',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),

          // Imagen del ítem
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child:
                  item.imageUrl.isNotEmpty
                      ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: const Color(0xFFD91010),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
            ),
          ),

          // Título del ítem y detalles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y disponibilidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD91010).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Bs. ${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD91010),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              item.isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.isAvailable ? 'Disponible' : 'No disponible',
                          style: GoogleFonts.poppins(
                            color:
                                item.isAvailable ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Descripción
                  if (item.description.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Variaciones
                  if (item.variations.isNotEmpty) ...[
                    Text(
                      'Variaciones',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.variations
                        .map(
                          (variation) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                variation.name,
                                style: GoogleFonts.poppins(
                                  fontWeight:
                                      variation.isDefault
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                'Bs. ${variation.price.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFD91010),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle:
                                  variation.isDefault
                                      ? const Text('Variación predeterminada')
                                      : null,
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 24),
                  ],

                  // Categorías
                  if (item.categories.isNotEmpty) ...[
                    Text(
                      'Categorías',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          item.categories
                              .map(
                                (category) => Chip(
                                  label: Text(category),
                                  backgroundColor: theme.primaryColor
                                      .withOpacity(0.1),
                                  labelStyle: GoogleFonts.poppins(
                                    color: theme.primaryColor,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
