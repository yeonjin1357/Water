import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../models/water_intake.dart';
import '../localization/app_localizations.dart';
import 'history_bottom_sheet.dart';
import 'edit_intake_dialog.dart';

class HistorySection extends StatefulWidget {
  const HistorySection({super.key});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initItemAnimations(int itemCount) {
    // Clear existing controllers
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    _itemAnimations.clear();

    // Create new controllers for each item
    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 50)),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
      _itemControllers.add(controller);
      _itemAnimations.add(animation);
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterIntakeProvider>(
      builder: (context, provider, child) {
        if (_itemControllers.length != provider.todayIntakes.length) {
          _initItemAnimations(provider.todayIntakes.length);
        }

        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.97),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildContent(context, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF87CEEB), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.get('history'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer<WaterIntakeProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        '${provider.todayIntakes.length} ${AppLocalizations.get('entries')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const HistoryBottomSheet(),
              );
            },
            icon: const Icon(Icons.open_in_full, size: 16),
            label: Text(AppLocalizations.get('viewAll')),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF87CEEB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFF87CEEB).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WaterIntakeProvider provider) {
    if (provider.todayIntakes.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: provider.todayIntakes.length,
      itemBuilder: (context, index) {
        if (index < _itemAnimations.length) {
          return FadeTransition(
            opacity: _itemAnimations[index],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(_itemAnimations[index]),
              child: _buildHistoryItem(context, provider.todayIntakes[index], provider),
            ),
          );
        }
        return _buildHistoryItem(context, provider.todayIntakes[index], provider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF87CEEB).withOpacity(0.1),
                  const Color(0xFF64B5F6).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: const Color(0xFF87CEEB).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('noDrinksToday'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.get('startHydrating'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, WaterIntake intake, WaterIntakeProvider provider) {
    final time = '${intake.timestamp.hour.toString().padLeft(2, '0')}:${intake.timestamp.minute.toString().padLeft(2, '0')}';
    final drinkType = intake.note ?? 'Water';
    
    Map<String, dynamic> drinkStyle = _getDrinkStyle(drinkType);
    
    return Dismissible(
      key: Key(intake.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(AppLocalizations.get('deleteEntry')),
            content: Text(AppLocalizations.get('deleteConfirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.get('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.get('delete')),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await provider.removeIntake(intake.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: drinkStyle['shadowColor'].withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
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
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: drinkStyle['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: drinkStyle['shadowColor'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      drinkStyle['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drinkType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: drinkStyle['bgColor'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${intake.amount} ml',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: drinkStyle['color'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getDrinkStyle(String drinkType) {
    switch (drinkType) {
      case 'Tea':
        return {
          'icon': Icons.local_cafe,
          'color': Colors.brown,
          'gradient': [const Color(0xFFBCAAA4), const Color(0xFF8D6E63)],
          'bgColor': Colors.brown[50],
          'shadowColor': Colors.brown,
        };
      case 'Coffee':
        return {
          'icon': Icons.coffee,
          'color': Colors.brown[800],
          'gradient': [const Color(0xFF6D4C41), const Color(0xFF4E342E)],
          'bgColor': Colors.brown[50],
          'shadowColor': Colors.brown[800],
        };
      case 'Juice':
        return {
          'icon': Icons.local_drink,
          'color': Colors.orange,
          'gradient': [const Color(0xFFFFB74D), const Color(0xFFFF9800)],
          'bgColor': Colors.orange[50],
          'shadowColor': Colors.orange,
        };
      case 'Milk':
        return {
          'icon': Icons.local_dining,
          'color': Colors.grey[600],
          'gradient': [const Color(0xFFBDBDBD), const Color(0xFF757575)],
          'bgColor': Colors.grey[50],
          'shadowColor': Colors.grey,
        };
      default:
        return {
          'icon': Icons.water_drop,
          'color': Colors.blue[400],
          'gradient': [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
          'bgColor': Colors.blue[50],
          'shadowColor': Colors.blue,
        };
    }
  }
}