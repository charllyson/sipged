import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomDateField extends StatelessWidget {
  CustomDateField(
      {super.key, this.stream,
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
      this.firstDate,
      this.lastDate,
      this.hour,
      this.min
      });

  final DateFormat format = DateFormat('dd/MM/yyyy',);
  final Stream<String>? stream;
  final TextEditingController? controller;
  final String? hint;
  final DateTime? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormat;
  final Function(DateTime?)? onChanged;
  final Function(DateTime?)? onSaved;
  final String? Function(DateTime?)? validator;
  final bool? enabled;
  final Color? valueColor;
  final int? hour;
  final int? min;
  final String? labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) {
          return LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth;
                if (constraints.maxWidth >= 1000) {/// Desktop
                  maxWidth = 500;
                } else if (constraints.maxWidth >= 600) {/// Tablet
                  maxWidth = 400;
                } else {
                  maxWidth = constraints.maxWidth * 0.9; /// Mobile
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DateTimeField(
                      format: format,
                      onShowPicker: (context, currentValue) async {
                        final DateTime? time = await showDatePicker(
                          context: context,
                          initialDate: initialValue ?? DateTime.now(),
                          firstDate: firstDate ?? DateTime(DateTime.now().year-100,),
                          lastDate: lastDate ?? DateTime(DateTime.now().year+100,),);
                        return time;
                      },
                      onSaved: onSaved,
                      initialValue: initialValue,
                      validator: validator,
                      controller: controller,
                      obscureText: obscure,
                      keyboardType: textInputType,
                      inputFormatters: inputFormat,
                      onChanged: onChanged,
                      //enabled: enabled,
                      decoration: InputDecoration(
                        labelText: labelText,
                        hintText: hint,
                        prefixIcon: prefix,
                        suffixIcon: suffix,
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0,),
                          borderSide: const BorderSide(color: Colors.grey,),),
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
                      ),
                      //textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                );
              }
          );
        },);
  }
}
