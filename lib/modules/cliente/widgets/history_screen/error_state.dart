import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
