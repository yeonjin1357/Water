import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../widgets/modern_water_glass.dart';
import '../widgets/drink_settings_dialog.dart';
import '../widgets/history_bottom_sheet.dart';
import '../localization/app_localizations.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<WaterIntakeProvider>(
          builder: (context, provider, child) {
          final progress = provider.progress.clamp(0.0, 1.0);
          
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  ModernWaterGlass(
                    waterLevel: progress,
                    currentAmount: provider.todayTotal,
                    goalAmount: provider.userSettings.dailyGoal,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMainDrinkButton(
                        context,
                        amount: currentAmount,
                        drinkType: currentDrinkType,
                        onTap: () async => await provider.addWaterIntake(
                          currentAmount,
                          note: currentDrinkType,
                          drinkType: currentDrinkType.toLowerCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildSettingsIcon(context),
                      const SizedBox(width: 12),
                      _buildHistoryIcon(context),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildHistoryIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const HistoryBottomSheet(),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF87CEEB).withOpacity(0.2),
              const Color(0xFF64B5F6).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF87CEEB).withOpacity(0.3),
          ),
        ),
        child: const Icon(
          Icons.history,
          color: Color(0xFF87CEEB),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMainDrinkButton(
    BuildContext context, {
    required int amount,
    required String drinkType,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF64B5F6),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.get('drinkAmount', amount.toString()),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          drinkIcon,
          color: drinkColor,
          size: 24,
        ),
      ),
    );
  }

}