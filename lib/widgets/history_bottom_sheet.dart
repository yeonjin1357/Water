import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';

class HistoryBottomSheet extends StatelessWidget {
  const HistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
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
                child: Consumer<WaterIntakeProvider>(
                  builder: (context, provider, child) {
                    final groupedIntakes = _groupIntakesByDate(provider.todayIntakes);
                    
                    if (groupedIntakes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No drinks recorded yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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
                          0, (sum, intake) => sum + (intake.amount as int)
                        );
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      color: const Color(0xFF87CEEB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$totalAmount mL',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF87CEEB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Intake items
                            ...intakes.map((intake) => _buildHistoryItem(
                              context, intake, provider
                            )).toList(),
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

  Map<DateTime, List<dynamic>> _groupIntakesByDate(List<dynamic> intakes) {
    final Map<DateTime, List<dynamic>> grouped = {};
    
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
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final sortedMap = <DateTime, List<dynamic>>{};
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
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
            child: Icon(
              drinkIcon,
              color: drinkColor,
              size: 18,
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
              size: 18,
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