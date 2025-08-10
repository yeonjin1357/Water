import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/water_intake_provider.dart';
import '../models/water_intake.dart';
import '../models/user_settings.dart';
import 'edit_intake_dialog.dart';
import '../localization/app_localizations.dart';

class HistoryBottomSheet extends StatefulWidget {
  const HistoryBottomSheet({super.key});

  @override
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  late Future<List<WaterIntake>> _allIntakesFuture;

  @override
  void initState() {
    super.initState();
    _allIntakesFuture = context.read<WaterIntakeProvider>().getAllIntakes();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.get('history'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: FutureBuilder<List<WaterIntake>>(
                  future: _allIntakesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allIntakes = snapshot.data ?? [];
                    final groupedIntakes = _groupIntakesByDate(allIntakes);

                    if (groupedIntakes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.water_drop,
                              size: 80,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.get('noRecordsYet'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: groupedIntakes.length,
                      itemBuilder: (context, index) {
                        final date = groupedIntakes.keys.elementAt(index);
                        final intakes = groupedIntakes[date]!;
                        final totalAmount = intakes.fold<int>(
                          0,
                          (sum, intake) => sum + intake.amount,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(date),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF42A5F5,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      AppLocalizations.get(
                                        'totalAmount',
                                        totalAmount.toString(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF42A5F5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Intake items
                            ...intakes.map(
                              (intake) => _buildHistoryItem(
                                context,
                                intake,
                                context.read<WaterIntakeProvider>(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<DateTime, List<WaterIntake>> _groupIntakesByDate(
    List<WaterIntake> intakes,
  ) {
    final Map<DateTime, List<WaterIntake>> grouped = {};

    for (final intake in intakes) {
      final date = DateTime(
        intake.timestamp.year,
        intake.timestamp.month,
        intake.timestamp.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(intake);
      } else {
        grouped[date] = [intake];
      }
    }

    // Sort by date (newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final sortedMap = <DateTime, List<WaterIntake>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return AppLocalizations.get('dateToday');
    } else if (date == yesterday) {
      return AppLocalizations.get('dateYesterday');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WaterIntake intake,
    WaterIntakeProvider provider,
  ) {
    final time =
        '${intake.timestamp.hour.toString().padLeft(2, '0')}:${intake.timestamp.minute.toString().padLeft(2, '0')}';
    final drinkType = intake.note ?? 'Water';

    IconData drinkIcon = Symbols.water_full;
    Color drinkColor = Colors.blue[400]!;
    Color bgColor = Colors.blue[50]!;
    String displayName = drinkType;

    // Check if it's a custom drink
    final customDrink = provider.userSettings.customDrinks.firstWhere(
      (drink) => drink.name == drinkType,
      orElse: () => CustomDrink(id: '', name: '', color: Colors.blue),
    );

    if (customDrink.id.isNotEmpty) {
      // It's a custom drink
      drinkIcon = Icons.opacity;
      drinkColor = customDrink.color;
      bgColor = customDrink.color.withOpacity(0.1);
      displayName = customDrink.name;
    } else {
      // Default drinks
      displayName = AppLocalizations.getDrinkName(drinkType);
      switch (drinkType) {
        case 'Tea':
          drinkIcon = Symbols.emoji_food_beverage;
          drinkColor = Colors.brown;
          bgColor = Colors.brown[50]!;
          break;
        case 'Coffee':
          drinkIcon = Symbols.coffee;
          drinkColor = Colors.brown[800]!;
          bgColor = Colors.brown[50]!;
          break;
        case 'Juice':
          drinkIcon = Symbols.local_bar;
          drinkColor = Colors.orange;
          bgColor = Colors.orange[50]!;
          break;
        case 'Milk':
          drinkIcon = Symbols.local_drink;
          drinkColor = Colors.grey[600]!;
          bgColor = Colors.grey[50]!;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(drinkIcon, color: drinkColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${intake.amount} mL',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
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
                    const Icon(Icons.edit_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.get('edit'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.get('delete'),
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
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
                      setState(() {
                        _allIntakesFuture = provider.getAllIntakes();
                      });
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
                          Navigator.pop(context); // Close dialog first
                          await provider.removeIntake(intake.id);
                          if (mounted) {
                            setState(() {
                              _allIntakesFuture = provider.getAllIntakes();
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
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
