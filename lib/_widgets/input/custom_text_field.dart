import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.autofillHints,
    this.stream,
    this.initialValue,
    this.valueColor,
    this.prefixIcon,
    this.suffixIcon,
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
    this.onSubmitted,
    this.fillCollor,
    this.width,
    this.hintText,
    this.maxLines = 1,
    this.readOnly = false,

    // ─── NOVOS (opcionais) ────────────────────────────────────────────────
    this.textAlignVertical,
    this.isDense,
    this.isCollapsed,
    this.contentPadding,
    this.hintStyle,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
  });

  final List<String>? autofillHints;
  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hintText;                 // ← já existia, agora é usado
  final String? initialValue;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Function(String?)? onSaved;
  final bool? enabled;
  final Color? valueColor;
  final String? labelText;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autoCorrect;
  final Function(String)? onSubmitted;
  final Color? fillCollor;
  final double? width;
  final int? maxLines;
  final bool readOnly;

  // ─── NOVOS (opcionais) ───────────────────────────────────────────────────
  final TextAlignVertical? textAlignVertical;
  final bool? isDense;
  final bool? isCollapsed;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        readOnly: readOnly,
        maxLines: maxLines,
        onFieldSubmitted: onSubmitted,
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
        textAlignVertical: textAlignVertical, // ← permite centralizar verticalmente
        decoration: InputDecoration(
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: fillCollor ?? Colors.white,
          labelText: labelText,

          // ↓ agora realmente usamos hint
          hintText: hintText,
          hintStyle: hintStyle,

          // ↓ controles de altura/centralização
          isDense: isDense,
          isCollapsed: isCollapsed,
          contentPadding: contentPadding,

          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIconConstraints,
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIconConstraints,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade500),
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
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
