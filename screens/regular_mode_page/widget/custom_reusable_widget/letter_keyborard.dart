import 'package:flutter/material.dart';
import '../../../../Global/custom_colors.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onTextInput;
  final Function onBackspace;
  final Function onClose;

  const CustomKeyboard({
    required this.onTextInput,
    required this.onBackspace,
    required this.onClose,
    super.key,
  });

  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  bool _isUppercase = true;

  void _toggleCase() {
    setState(() {
      _isUppercase = !_isUppercase;
    });
  }

  void _textInputHandler(String text) => widget.onTextInput.call(text);

  void _backspaceHandler() => widget.onBackspace.call();

  void _closeHandler() => widget.onClose.call();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      height: 220,
      color: CustomColors.whiteColor,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Expanded(
            child: _buildRow('1234567890'),
          ),
          Expanded(
            child: _buildRow('QWERTYUIOP'),
          ),
          Expanded(
            child: _buildRow('ASDFGHJKL'),
          ),
          Expanded(
            child: _buildRow('ZXCVBNM'),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildKey(
                    _isUppercase
                        ? 'Caps'
                        : 'caps', // Toggle between Caps and caps
                    _toggleCase,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildKey(
                    'Space',
                    () => _textInputHandler(' '),
                  ),
                ),
                Expanded(
                  child: _buildKey(
                    '.',
                    () => _textInputHandler('.'),
                  ),
                ),
                Expanded(
                  child: _buildKey(
                    '<-',
                    _backspaceHandler,
                  ),
                ),
                Expanded(
                  child: _buildKey(
                    'close',
                    _closeHandler,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.split('').map((letter) {
        return Expanded(
          child: _buildKey(
            _isUppercase ? letter : letter.toLowerCase(),
            () =>
                _textInputHandler(_isUppercase ? letter : letter.toLowerCase()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: CustomColors.whiteColor,
          border: Border.all(color: CustomColors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
