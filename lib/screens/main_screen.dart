import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../widgets/water_glass_widget.dart';
import '../widgets/drink_settings_dialog.dart';
import '../widgets/history_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String currentDrinkType = 'Water';
  int currentAmount = 250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Consumer<WaterIntakeProvider>(
        builder: (context, provider, child) {
          final progress = provider.progress.clamp(0.0, 1.0);
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        WaterGlassWidget(
                          waterLevel: progress,
                          currentAmount: provider.todayTotal,
                          goalAmount: provider.userSettings.dailyGoal,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMainDrinkButton(
                              context,
                              amount: currentAmount,
                              drinkType: currentDrinkType,
                              onTap: () => provider.addWaterIntake(currentAmount, note: currentDrinkType),
                            ),
                            const SizedBox(width: 12),
                            _buildSettingsIcon(context),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              _buildHistorySection(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainDrinkButton(
    BuildContext context, {
    required int amount,
    required String drinkType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87CEEB).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Drink ($amount mL)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsIcon(BuildContext context) {
    IconData drinkIcon = Icons.water_drop;
    Color drinkColor = Colors.blue[400]!;
    
    switch (currentDrinkType) {
      case 'Tea':
        drinkIcon = Icons.local_cafe;
        drinkColor = Colors.brown;
        break;
      case 'Coffee':
        drinkIcon = Icons.coffee;
        drinkColor = Colors.brown[800]!;
        break;
      case 'Juice':
        drinkIcon = Icons.local_drink;
        drinkColor = Colors.orange;
        break;
      case 'Milk':
        drinkIcon = Icons.local_dining;
        drinkColor = Colors.grey[600]!;
        break;
    }
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => DrinkSettingsDialog(
            currentAmount: currentAmount,
            onConfirm: (amount, drinkType) {
              setState(() {
                currentAmount = amount;
                currentDrinkType = drinkType;
              });
            },
          ),
        );
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          drinkIcon,
          color: drinkColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, dynamic provider) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const HistoryBottomSheet(),
                    );
                  },
                  child: const Text(
                    'View All →',
                    style: TextStyle(
                      color: Color(0xFF87CEEB),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.todayIntakes.isEmpty
              ? Center(
                  child: Text(
                    'No drinks yet today',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.todayIntakes.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(context, provider.todayIntakes[index], provider);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, dynamic intake, dynamic provider) {
    final time = '${intake.timestamp.hour.toString().padLeft(2, '0')}:${intake.timestamp.minute.toString().padLeft(2, '0')}';
    final drinkType = intake.note ?? 'Water';
    
    IconData drinkIcon = Icons.water_drop;
    Color drinkColor = Colors.blue[400]!;
    Color bgColor = Colors.blue[50]!;
    
    switch (drinkType) {
      case 'Tea':
        drinkIcon = Icons.local_cafe;
        drinkColor = Colors.brown;
        bgColor = Colors.brown[50]!;
        break;
      case 'Coffee':
        drinkIcon = Icons.coffee;
        drinkColor = Colors.brown[800]!;
        bgColor = Colors.brown[50]!;
        break;
      case 'Juice':
        drinkIcon = Icons.local_drink;
        drinkColor = Colors.orange;
        bgColor = Colors.orange[50]!;
        break;
      case 'Milk':
        drinkIcon = Icons.local_dining;
        drinkColor = Colors.grey[600]!;
        bgColor = Colors.grey[50]!;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              drinkIcon,
              color: drinkColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drinkType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${intake.amount} mL',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[400],
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Entry'),
                  content: const Text('Are you sure you want to delete this entry?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        provider.removeIntake(intake.id);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}