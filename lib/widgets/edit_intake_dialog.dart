import 'package:flutter/material.dart';
import '../models/water_intake.dart';
import '../localization/app_localizations.dart';

class EditIntakeDialog extends StatefulWidget {
  final WaterIntake intake;
  final Function(int amount, String drinkType) onConfirm;
  
  const EditIntakeDialog({
    super.key,
    required this.intake,
    required this.onConfirm,
  });

  @override
  State<EditIntakeDialog> createState() => _EditIntakeDialogState();
}

class _EditIntakeDialogState extends State<EditIntakeDialog> {
  late String selectedDrink;
  late int selectedAmount;
  late TextEditingController customAmountController;
  
  final List<String> drinkTypes = ['Water', 'Tea', 'Coffee', 'Juice', 'Milk'];
  final List<int> presetAmounts = [100, 200, 250, 300, 500];
  
  @override
  void initState() {
    super.initState();
    selectedDrink = widget.intake.note ?? 'Water';
    selectedAmount = widget.intake.amount;
    customAmountController = TextEditingController(text: selectedAmount.toString());
  }
  
  @override
  void dispose() {
    customAmountController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        AppLocalizations.get('editDrink'),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('drinkType'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drinkTypes.map((drink) {
                final isSelected = selectedDrink == drink;
                IconData icon;
                Color color;
                
                switch (drink) {
                  case 'Tea':
                    icon = Icons.local_cafe;
                    color = Colors.brown;
                    break;
                  case 'Coffee':
                    icon = Icons.coffee;
                    color = Colors.brown.shade800;
                    break;
                  case 'Juice':
                    icon = Icons.local_drink;
                    color = Colors.orange;
                    break;
                  case 'Milk':
                    icon = Icons.local_dining;
                    color = Colors.grey.shade600;
                    break;
                  default:
                    icon = Icons.water_drop;
                    color = Colors.blue.shade400;
                }
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDrink = drink;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          drink,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              '${AppLocalizations.get('amount')} (ml)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetAmounts.map((amount) {
                final isSelected = selectedAmount == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAmount = amount;
                      customAmountController.text = amount.toString();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF42A5F5).withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF42A5F5)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$amount mL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF42A5F5)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('customAmount'),
                suffixText: 'mL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    selectedAmount = int.tryParse(value) ?? selectedAmount;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.get('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(selectedAmount, selectedDrink);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(AppLocalizations.get('save')),
        ),
      ],
    );
  }
}