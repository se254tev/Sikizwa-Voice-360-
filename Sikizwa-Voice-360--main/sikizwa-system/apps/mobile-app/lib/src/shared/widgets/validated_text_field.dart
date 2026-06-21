import 'package:flutter/material.dart';

class AppValidatedTextField extends StatefulWidget {
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
    this.enablePasswordToggle = false,
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
  final bool enablePasswordToggle;

  @override
  State<AppValidatedTextField> createState() => _AppValidatedTextFieldState();
}

class _AppValidatedTextFieldState extends State<AppValidatedTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentValue = widget.controller.text.trim();
    final validationError = widget.validator?.call(currentValue);
    final hasValue = currentValue.isNotEmpty;
    final isValid = hasValue && validationError == null;

    Widget? suffix;
    if (widget.enablePasswordToggle) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
            splashRadius: 20,
          ),
          if (hasValue)
            Icon(
              isValid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: isValid ? Colors.green.shade700 : theme.colorScheme.error,
            ),
        ],
      );
    } else {
      suffix = hasValue
          ? Icon(
              isValid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: isValid ? Colors.green.shade700 : theme.colorScheme.error,
            )
          : null;
    }

    return Semantics(
      label: widget.label,
      hint: widget.helperText,
      liveRegion: true,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscure,
        obscuringCharacter: widget.obscuringCharacter,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        autofillHints: widget.autofillHints,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          helperText: widget.helperText,
          helperStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.68),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isValid ? Colors.green.shade700 : theme.colorScheme.primary,
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
