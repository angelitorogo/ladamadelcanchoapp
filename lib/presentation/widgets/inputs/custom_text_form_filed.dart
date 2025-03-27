import 'package:flutter/material.dart';

class CustomTextFormFiled extends StatelessWidget {
  final IconData? prefixIcon;
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool? obscureText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool? enabled;
  final String? initialValue; // 🔥 Agregamos el parámetro

  const CustomTextFormFiled({
    super.key, 
    this.label, 
    this.hint, 
    this.errorMessage, 
    this.onChanged, 
    this.validator, 
    this.enabled,
    this.prefixIcon, 
    this.obscureText,
    this.initialValue, // ✅ Agregamos el nuevo parámetro
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final borderEnabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final disabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), // 🔥 Bordes grises cuando está deshabilitado
    );

    return TextFormField(
      initialValue: initialValue, // ✅ Ahora soporta valores iniciales
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      obscureText: obscureText ?? false,
      style: TextStyle(
        color: enabled == false ? Colors.grey.shade600 : Colors.white70, // 🔥 Cambia el color del texto
      ),

      decoration: InputDecoration(
        enabledBorder: borderEnabled.copyWith(borderSide: BorderSide(color: colors.primary)),
        focusedBorder: borderEnabled.copyWith(borderSide: BorderSide(color: colors.primary)),
        disabledBorder: disabledBorder.copyWith(borderSide: BorderSide(color: Colors.grey.shade600)), // ✅ Cambia el borde cuando está deshabilitado
        label: label != null 
          ? Text(label!, style: TextStyle(color: colors.primary)) 
          : null,
        labelStyle: TextStyle(
          color: enabled == false ? Colors.grey.shade600 : colors.primary, // 🔥 Cambia el color del label
        ),
        focusColor: colors.primary,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colors.primary) : null,
        hintText: hint,
        errorText: errorMessage,
        errorBorder: borderEnabled.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder: borderEnabled.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true, // Un poco más pequeño el input en general
      ),
    );
  }
}
