import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/user_settings.dart';
import '../localization/app_localizations.dart';

class CustomDrinkDialog extends StatefulWidget {
  final CustomDrink? drink;
  final Function(String name, Color color) onConfirm;

  const CustomDrinkDialog({
    Key? key,
    this.drink,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CustomDrinkDialog> createState() => _CustomDrinkDialogState();
}

class _CustomDrinkDialogState extends State<CustomDrinkDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  
  final List<Color> _availableColors = [
    const Color(0xFFFF6B6B), // Red
    const Color(0xFFFF9F43), // Orange
    const Color(0xFFFECA57), // Yellow
    const Color(0xFF48BFE3), // Light Blue
    const Color(0xFF5F27CD), // Purple
    const Color(0xFF00D2D3), // Cyan
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFF54A0FF), // Blue
    const Color(0xFF10AC84), // Green
    const Color(0xFFA55EEA), // Violet
    const Color(0xFF575FCF), // Indigo
    const Color(0xFFFC5C65), // Coral
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.drink?.name ?? '');
    _selectedColor = widget.drink?.color ?? _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.local_drink,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.drink != null ? AppLocalizations.get('editCustomDrink') : AppLocalizations.get('addCustomDrink'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Name input
            Text(
              AppLocalizations.get('drinkName'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.get('drinkNameHint'),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            
            // Color selection
            Text(
              AppLocalizations.get('selectColor'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _selectedColor.withOpacity(0.8),
                          _selectedColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.opacity,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nameController.text.isEmpty ? AppLocalizations.get('drinkName') : _nameController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.get('cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _nameController.text.isNotEmpty
                      ? () {
                          widget.onConfirm(_nameController.text, _selectedColor);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(widget.drink != null ? AppLocalizations.get('save') : AppLocalizations.get('add')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}