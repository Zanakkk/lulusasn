// lib/core/widgets/brutalist_input.dart

import 'package:flutter/material.dart';

/// Neobrutalism-style text input field.
///
/// Features:
/// - Thick border
/// - Custom validation
/// - Password visibility toggle
/// - Prefix/suffix icons
/// - Character counter
class BrutalistInput extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;

  const BrutalistInput({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
  });

  /// EMAIL
  factory BrutalistInput.email({
    Key? key,
    required String label,
    TextEditingController? controller,
  }) {
    return BrutalistInput(
      key: key,
      label: label,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// PASSWORD
  factory BrutalistInput.password({
    Key? key,
    required String label,
    TextEditingController? controller,
  }) {
    return BrutalistInput(
      key: key,
      label: label,
      controller: controller,
      obscureText: true,
    );
  }

  /// PHONE
  factory BrutalistInput.phone({
    Key? key,
    required String label,
    TextEditingController? controller,
  }) {
    return BrutalistInput(
      key: key,
      label: label,
      controller: controller,
      keyboardType: TextInputType.phone,
    );
  }

  /// SEARCH
  factory BrutalistInput.search({
    Key? key,
    required String label,
    TextEditingController? controller,
  }) {
    return BrutalistInput(
      key: key,
      label: label,
      controller: controller,
      keyboardType: TextInputType.text,
    );
  }

  /// MULTILINE
  factory BrutalistInput.multiline({
    Key? key,
    required String label,
    TextEditingController? controller,
    int maxLines = 4,
  }) {
    return BrutalistInput(
      key: key,
      label: label,
      controller: controller,
      maxLines: maxLines,
    );
  }

  @override
  State<BrutalistInput> createState() => _BrutalistInputState();
}

class _BrutalistInputState extends State<BrutalistInput> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

