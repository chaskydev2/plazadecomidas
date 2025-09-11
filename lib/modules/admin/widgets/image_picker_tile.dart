import 'dart:typed_data';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/admin/services/admin_service.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';
import 'package:kokorestaurant/modules/admin/widgets/empty_imagen.dart';
import 'package:kokorestaurant/modules/admin/widgets/section_title.dart';

class ImagePickerTile extends StatelessWidget {
  final String title;
  final String placeholder;
  final VoidCallback onPick;
  final String? networkUrl;
  final XFile? xfile;
  final Uint8List? webBytes;
  final double height;
  final double width;
  final bool isCircle;
  final Color? color;

  const ImagePickerTile({
    required this.title,
    required this.placeholder,
    required this.onPick,
    this.networkUrl,
    this.xfile,
    this.webBytes,
    required this.height,
    required this.width,
    this.isCircle = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isCircle ? width / 2 : 12),
    );
    final primary = color ?? AppColors.primary;

    Widget childWidget;
    if (xfile != null) {
      childWidget =
          kIsWeb
              ? (webBytes != null
                  ? Image.memory(webBytes!, fit: BoxFit.cover)
                  : const EmptyImage())
              : Image.file(File(xfile!.path), fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      childWidget = Image.network(networkUrl!, fit: BoxFit.cover);
    } else {
      childWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCircle ? Icons.add_photo_alternate : Icons.add_a_photo,
            size: 32,
            color: primary,
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona una imagen',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(isCircle ? width / 2 : 12),
        child: Ink(
          decoration: ShapeDecoration(
            shape: border,
            color: Colors.white,
            shadows: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCircle ? width / 2 : 12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                childWidget,
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Cambiar',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    color: primary.withOpacity(0.85),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
