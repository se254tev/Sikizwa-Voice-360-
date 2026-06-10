import 'package:flutter/material.dart';

class AppValidatedTextField extends StatelessWidget {
  const AppValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.obscuringCharacter = '•',
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String obscuringCharacter;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentValue = controller.text.trim();
    final validationError = validator?.call(currentValue);
    final hasValue = currentValue.isNotEmpty;
    final isValid = hasValue && validationError == null;

    return Semantics(
      label: label,
      hint: helperText,
      liveRegion: true,
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        obscuringCharacter: obscuringCharacter,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        autofillHints: autofillHints,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          helperStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.68),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          suffixIcon: hasValue
              ? Icon(
                  isValid
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: isValid
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isValid
                  ? Colors.green.shade700
                  : theme.colorScheme.primary,
              width: 1.6,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.8),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
