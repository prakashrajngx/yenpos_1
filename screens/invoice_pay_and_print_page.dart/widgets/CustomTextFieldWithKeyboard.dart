import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Global/custom_sized_box.dart';
import '../../regular_mode_page/widget/custom_reusable_widget/letter_keyborard.dart';

// Custom TextField with Virtual Keyboard
class CustomTextFieldWithKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isReadOnly;
  final ValueChanged<String>? onChanged; // Optional onChanged callback
  final List<TextInputFormatter>? inputFormatters; // Optional inputFormatters

  const CustomTextFieldWithKeyboard({
    super.key,
    required this.controller,
    required this.label,
    this.isReadOnly = true,
    this.onChanged,
    this.inputFormatters, // Optional inputFormatters
  });

  void _showCustomKeyboard(BuildContext context) {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return CustomKeyboard(
          onTextInput: (value) {
            controller.text += value;
            if (onChanged != null) {
              onChanged!(controller.text); // Call onChanged if provided
            }
          },
          onBackspace: () {
            if (controller.text.isNotEmpty) {
              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
              if (onChanged != null) {
                onChanged!(controller.text); // Call onChanged if provided
              }
            }
          },
          onClose: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomSizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: () {
          _showCustomKeyboard(context);
        },
        onChanged: onChanged, // Trigger changes dynamically
        inputFormatters: inputFormatters ?? [],
        decoration: InputDecoration(
          label: Text(label),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
