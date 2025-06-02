import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextMaxLinesField extends StatelessWidget {
  const CustomTextMaxLinesField(
      {
      super.key,
      this.stream,
      this.hint,
      this.initialValue,
      this.valueColor,
      this.prefix,
      this.suffix,
      this.inputFormat,
      this.obscure = false,
      this.textInputType,
      this.onChanged,
      this.onSaved,
      this.enabled,
      this.controller,
      this.validator,
      this.labelText,
      this.maxLines,
      this.maxLength,
      this.minLines,});

  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final String? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormat;
  final String? Function(String?)? validator;
  final Function(String?,)? onChanged;
  final Function(String?,)? onSaved;
  final bool? enabled;
  final Color? valueColor;
  final String? labelText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextFormField(
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          controller: controller,
          obscureText: obscure,
          initialValue: initialValue,
          enabled: enabled,
          validator: validator,
          onSaved: onSaved,
          onChanged: onChanged,
          keyboardType: textInputType,
          inputFormatters: inputFormat,
          decoration: InputDecoration(
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              labelText: labelText,
              prefixIcon: prefix,
              suffixIcon: suffix,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                  borderSide: const BorderSide(color: Colors.grey,),),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                  borderSide: const BorderSide(color: Colors.blue,),),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                  borderSide: const BorderSide(color: Colors.red,),),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                  borderSide: const BorderSide(color: Colors.red,),),
              disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0,),
                  borderSide: const BorderSide(color: Colors.grey,),),),),
    );
  }
}
