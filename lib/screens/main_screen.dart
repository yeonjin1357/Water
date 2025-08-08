import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../widgets/modern_water_glass.dart';
import '../widgets/drink_settings_dialog.dart';
import '../widgets/history_bottom_sheet.dart';
import '../widgets/edit_intake_dialog.dart';
import '../models/water_intake.dart';
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
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
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
                          ],
                        ),
                        const SizedBox(height: 20),
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
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
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.02),
              blurRadius: 6,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
                Text(
                  AppLocalizations.get('history'),
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
                  child: Text(
                    AppLocalizations.get('viewAll'),
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
                    AppLocalizations.get('noDrinksToday'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        color: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 30),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('edit')),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('delete'), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                showDialog(
                  context: context,
                  builder: (context) => EditIntakeDialog(
                    intake: intake,
                    onConfirm: (amount, drinkType) async {
                      final updatedIntake = WaterIntake(
                        id: intake.id,
                        amount: amount,
                        timestamp: intake.timestamp,
                        note: drinkType,
                      );
                      await provider.updateIntake(updatedIntake);
                    },
                  ),
                );
              } else if (value == 'delete') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.get('deleteEntry')),
                    content: Text(AppLocalizations.get('deleteConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.get('cancel')),
                      ),
                      TextButton(
                        onPressed: () async {
                          await provider.removeIntake(intake.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(AppLocalizations.get('delete')),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}