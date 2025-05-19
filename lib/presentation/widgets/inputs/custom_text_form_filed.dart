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
  final String? initialValue;
  final TextEditingController? controller;

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
    this.initialValue,
    this.controller, // ✅ NUEVO
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final borderEnabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return TextFormField(
      controller: controller, // ✅ reemplaza initialValue
      initialValue: controller == null ? initialValue : null, // ⚠️ Solo si no hay controller
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      obscureText: obscureText ?? false,
      style: TextStyle(
        color: enabled == false ? Colors.grey.shade600 : Colors.white70,
      ),
      decoration: InputDecoration(
        enabledBorder: borderEnabled.copyWith(borderSide: BorderSide(color: colors.primary)),
        focusedBorder: borderEnabled.copyWith(borderSide: BorderSide(color: colors.primary)),
        disabledBorder: borderEnabled.copyWith(borderSide: BorderSide(color: Colors.grey.shade600)),
        label: label != null
            ? Text(label!, style: TextStyle(color: colors.primary))
            : null,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: colors.primary) : null,
        hintText: hint,
        errorText: errorMessage,
        errorBorder: borderEnabled.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder: borderEnabled.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true,
      ),
    );
  }
}
