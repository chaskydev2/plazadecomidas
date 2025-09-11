import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/material.dart';

class EmptyImage extends StatelessWidget {
  const EmptyImage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: Colors.black45,
      ),
    );
  }
}
