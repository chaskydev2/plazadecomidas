import 'dart:typed_data';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kokorestaurant/core/models/restaurant.dart';
import 'package:kokorestaurant/modules/admin/services/admin_service.dart';
import 'package:kokorestaurant/core/themes/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color; // ignorado para mantener blanco/negro + primary
  const SectionTitle(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.restaurant, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
