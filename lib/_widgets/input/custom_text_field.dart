import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.autofillHints,
    this.stream,
    this.hint,
    this.initialValue,
    this.valueColor,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onSaved,
    this.enabled,
    this.controller,
    this.validator,
    this.labelText,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
    this.autoCorrect = true,
  });

  final List<String>? autofillHints;
  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final String? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;
  final Function(String?)? onSaved;
  final bool? enabled;
  final Color? valueColor;
  final String? labelText;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autoCorrect;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autocorrect: autoCorrect,
      textInputAction: textInputAction,
      focusNode: focusNode,
      maxLength: maxLength,
      controller: controller,
      obscureText: obscure,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        labelText: labelText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
