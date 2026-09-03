import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Numeric keypad and direct text input dialog for high-speed quantity entry at counter
class NumpadQuantityDialog extends StatefulWidget {
  final String itemName;
  final int initialQuantity;
  final Function(int quantity) onConfirm;

  const NumpadQuantityDialog({
    super.key,
    required this.itemName,
    required this.initialQuantity,
    required this.onConfirm,
  });

  @override
  State<NumpadQuantityDialog> createState() => _NumpadQuantityDialogState();
}

class _NumpadQuantityDialogState extends State<NumpadQuantityDialog> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialQuantity.toString());
    // Auto-select text so typing immediately replaces it
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textController.text.length,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _append(String digit) {
    setState(() {
      var current = _textController.text;
      if (current == '0' || current == '1' && widget.initialQuantity == 1 && current.length == 1) {
        _textController.text = digit;
      } else {
        if (current.length < 5) {
          _textController.text = current + digit;
        }
      }
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _backspace() {
    setState(() {
      var current = _textController.text;
      if (current.length > 1) {
        _textController.text = current.substring(0, current.length - 1);
      } else {
        _textController.text = '1';
      }
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _setPreset(int val) {
    setState(() {
      _textController.text = val.toString();
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _confirm() {
    final qty = int.tryParse(_textController.text) ?? 1;
    widget.onConfirm(qty > 0 ? qty : 1);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Quantity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.itemName,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Direct Typeable Input Field
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onSubmitted: (_) => _confirm(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                filled: true,
                fillColor: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
                ),
                helperText: 'Type directly or use keypad / presets below',
                helperStyle: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Preset Chips (+5, +10, +20, +50, +100)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [10, 20, 50, 100].map((preset) {
                return InkWell(
                  onTap: () => _setPreset(preset),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$preset',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 3x4 Tactile Numpad Grid
            Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 8),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 8),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildButton('C', color: Colors.orange.shade100, textColor: Colors.orange.shade900, onTap: () {
                      setState(() {
                        _textController.text = '1';
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildButton('0', onTap: () => _append('0')),
                    const SizedBox(width: 8),
                    _buildButton('⌫', color: Colors.red.shade100, textColor: Colors.red.shade900, onTap: _backspace),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Confirm Button
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Row(
      children: [
        _buildButton(values[0], onTap: () => _append(values[0])),
        const SizedBox(width: 8),
        _buildButton(values[1], onTap: () => _append(values[1])),
        const SizedBox(width: 8),
        _buildButton(values[2], onTap: () => _append(values[2])),
      ],
    );
  }

  Widget _buildButton(
    String label, {
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: color ?? (isDark ? AppColors.cardDarkElevated : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
