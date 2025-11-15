import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool full;

  const CustomButton({required this.label, required this.onPressed, this.full = true, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: full ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
