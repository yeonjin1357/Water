import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

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

class _DrinkSettingsDialogState extends State<DrinkSettingsDialog> with TickerProviderStateMixin {
  late int selectedAmount;
  String selectedDrink = 'Water';
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _customAmountController = TextEditingController();

  final List<int> amounts = [100, 150, 200, 250, 300, 350, 400, 500];
  final List<Map<String, dynamic>> drinks = [
    {'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue, 'gradient': [Color(0xFF64B5F6), Color(0xFF42A5F5)]},
    {'name': 'Tea', 'icon': Icons.local_cafe, 'color': Colors.brown, 'gradient': [Color(0xFFBCAAA4), Color(0xFF8D6E63)]},
    {'name': 'Coffee', 'icon': Icons.coffee, 'color': Colors.brown[800], 'gradient': [Color(0xFF6D4C41), Color(0xFF4E342E)]},
    {'name': 'Juice', 'icon': Icons.local_drink, 'color': Colors.orange, 'gradient': [Color(0xFFFFB74D), Color(0xFFFF9800)]},
    {'name': 'Milk', 'icon': Icons.local_dining, 'color': Colors.grey[600], 'gradient': [Color(0xFFBDBDBD), Color(0xFF757575)]},
  ];

  @override
  void initState() {
    super.initState();
    selectedAmount = widget.currentAmount;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              elevation: 24,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),

                    _buildDrinkSelection(context),
                    const SizedBox(height: 28),

                    _buildAmountSelection(context),
                    const SizedBox(height: 24),

                    _buildCustomAmountInput(context),
                    const SizedBox(height: 28),

                    _buildConfirmButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.get('drinkSettings'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
  
  Widget _buildDrinkSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_drink, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.get('selectDrink'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: drinks.length,
            itemBuilder: (context, index) {
              final drink = drinks[index];
              final isSelected = selectedDrink == drink['name'];

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: isSelected ? 1 : 0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDrink = drink['name'];
                      });
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: drink['gradient'],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !isSelected
                            ? Theme.of(context).colorScheme.surfaceContainerLowest
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Theme.of(context).dividerColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (drink['gradient'][0] as Color).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1 + (value * 0.1),
                            child: Icon(
                              drink['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : drink['color'],
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            drink['name'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmountSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.get('selectAmount'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceEvenly,
            children: amounts.map((amount) {
              final isSelected = selectedAmount == amount;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: isSelected ? 1 : 0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = amount;
                        _customAmountController.clear();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                              )
                            : null,
                        color: !isSelected
                            ? Theme.of(context).colorScheme.surface
                            : null,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(0xFF42A5F5).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Text(
                        '$amount ml',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCustomAmountInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _customAmountController,
        decoration: InputDecoration(
          labelText: AppLocalizations.get('customAmount'),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.edit_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixText: 'ml',
          suffixStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
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
    );
  }
  
  Widget _buildConfirmButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF42A5F5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  widget.onConfirm(selectedAmount, selectedDrink);
                  Navigator.pop(context);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${AppLocalizations.get('confirm')} ($selectedAmount ml)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
