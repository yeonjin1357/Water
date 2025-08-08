import 'package:flutter/material.dart';

class DrinkSettingsDialog extends StatefulWidget {
  final int currentAmount;
  final Function(int amount, String drinkType) onConfirm;

  const DrinkSettingsDialog({
    super.key,
    required this.currentAmount,
    required this.onConfirm,
  });

  @override
  State<DrinkSettingsDialog> createState() => _DrinkSettingsDialogState();
}

class _DrinkSettingsDialogState extends State<DrinkSettingsDialog> {
  late int selectedAmount;
  String selectedDrink = 'Water';

  final List<int> amounts = [100, 150, 200, 250, 300, 350, 400, 500];
  final List<Map<String, dynamic>> drinks = [
    {'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Tea', 'icon': Icons.local_cafe, 'color': Colors.brown},
    {'name': 'Coffee', 'icon': Icons.coffee, 'color': Colors.brown[800]},
    {'name': 'Juice', 'icon': Icons.local_drink, 'color': Colors.orange},
    {'name': 'Milk', 'icon': Icons.local_dining, 'color': Colors.grey[600]},
  ];

  @override
  void initState() {
    super.initState();
    selectedAmount = widget.currentAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Drink Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Drink Type Selection
            const Text(
              'Select Drink',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: drinks.length,
                itemBuilder: (context, index) {
                  final drink = drinks[index];
                  final isSelected = selectedDrink == drink['name'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDrink = drink['name'];
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF87CEEB).withOpacity(0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF87CEEB)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            drink['icon'],
                            color: isSelected
                                ? const Color(0xFF87CEEB)
                                : drink['color'],
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drink['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? const Color(0xFF87CEEB)
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Amount Selection
            const Text(
              'Select Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: amounts.map((amount) {
                final isSelected = selectedAmount == amount;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAmount = amount;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF87CEEB)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF87CEEB)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '$amount ml',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Custom Amount Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Custom Amount (ml)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null && amount > 0) {
                  setState(() {
                    selectedAmount = amount;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(selectedAmount, selectedDrink);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Confirm ($selectedAmount ml)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
