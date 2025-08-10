import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../models/user_settings.dart';
import '../localization/app_localizations.dart';
import '../widgets/notification_settings_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _itemControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );
    
    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
    }).toList();
    
    _fadeController.forward();
    _slideController.forward();
    for (var controller in _itemControllers) {
      controller.forward();
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getNotificationSubtitle(WaterIntakeProvider provider) {
    final reminders = provider.userSettings.waterReminders;
    if (reminders.isEmpty) {
      return AppLocalizations.currentLanguage == 'ko' ? '꺼짐' : 'Off';
    }
    
    final enabledCount = reminders.where((r) => r.isEnabled).length;
    if (enabledCount == 0) {
      return AppLocalizations.currentLanguage == 'ko' ? '모든 알림 비활성화' : 'All disabled';
    }
    
    return AppLocalizations.currentLanguage == 'ko' 
        ? '$enabledCount개 알림 활성화' 
        : '$enabledCount notification${enabledCount > 1 ? 's' : ''} enabled';
  }
  
  void _showLanguageDialog(BuildContext context, WaterIntakeProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF87CEEB), Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.get('language'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLanguageOption(
                  context,
                  '한국어',
                  'ko',
                  provider.userSettings.language == 'ko',
                  () => _updateLanguage(provider, 'ko', context),
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  context,
                  'English',
                  'en',
                  provider.userSettings.language == 'en',
                  () => _updateLanguage(provider, 'en', context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                )
              : null,
          color: !isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateLanguage(WaterIntakeProvider provider, String language, BuildContext context) {
    final newSettings = UserSettings(
      dailyGoal: provider.userSettings.dailyGoal,
      reminderInterval: provider.userSettings.reminderInterval,
      reminderStartTime: provider.userSettings.reminderStartTime,
      reminderEndTime: provider.userSettings.reminderEndTime,
      defaultAmount: provider.userSettings.defaultAmount,
      isDarkMode: provider.userSettings.isDarkMode,
      language: language,
      notificationsEnabled: provider.userSettings.notificationsEnabled,
      persistentNotificationEnabled: provider.userSettings.persistentNotificationEnabled,
      customDrinks: provider.userSettings.customDrinks,
      waterReminders: provider.userSettings.waterReminders,
    );
    provider.updateSettings(newSettings);
    Navigator.of(context).pop();
  }

  void _showDailyGoalDialog(BuildContext context, WaterIntakeProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.userSettings.dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF87CEEB), Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.get('setDailyGoal'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.get('enterDailyGoal'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      suffixText: 'ml',
                      suffixStyle: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.get('recommendedAmount'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.get('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            final newGoal = int.tryParse(controller.text);
                            if (newGoal != null && newGoal > 0) {
                              final newSettings = UserSettings(
                                dailyGoal: newGoal,
                                reminderInterval: provider.userSettings.reminderInterval,
                                reminderStartTime: provider.userSettings.reminderStartTime,
                                reminderEndTime: provider.userSettings.reminderEndTime,
                                defaultAmount: provider.userSettings.defaultAmount,
                                isDarkMode: provider.userSettings.isDarkMode,
                                language: provider.userSettings.language,
                                notificationsEnabled: provider.userSettings.notificationsEnabled,
                                persistentNotificationEnabled: provider.userSettings.persistentNotificationEnabled,
                                customDrinks: provider.userSettings.customDrinks,
                                waterReminders: provider.userSettings.waterReminders,
                              );
                              provider.updateSettings(newSettings);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.get('goalChanged', newGoal.toString())),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF42A5F5),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.get('save'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<WaterIntakeProvider>(
          builder: (context, provider, child) {
            return FadeTransition(
              opacity: _fadeController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildSettingItem(
                      context,
                      index: 0,
                      icon: Icons.flag,
                      iconGradient: [const Color(0xFF87CEEB), const Color(0xFF64B5F6)],
                      title: AppLocalizations.get('dailyGoal'),
                      subtitle: '${provider.userSettings.dailyGoal} ml',
                      onTap: () => _showDailyGoalDialog(context, provider),
                    ),
                    const SizedBox(height: 16),
                    _buildDarkModeItem(context, provider),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      index: 2,
                      icon: Icons.language,
                      iconGradient: [const Color(0xFFFFB74D), const Color(0xFFFF9800)],
                      title: AppLocalizations.get('language'),
                      subtitle: provider.userSettings.language == 'ko' ? '한국어' : 'English',
                      onTap: () => _showLanguageDialog(context, provider),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingItem(
                      context,
                      index: 3,
                      icon: Icons.notifications_outlined,
                      iconGradient: [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
                      title: AppLocalizations.get('notifications'),
                      subtitle: _getNotificationSubtitle(provider),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const NotificationSettingsDialog(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPersistentNotificationItem(context, provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF87CEEB), Color(0xFF64B5F6)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          AppLocalizations.get('settings'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _itemAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(_itemAnimations[index]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconGradient[0].withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: iconGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
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
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDarkModeItem(BuildContext context, WaterIntakeProvider provider) {
    return FadeTransition(
      opacity: _itemAnimations[1],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(_itemAnimations[1]),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAB47BC), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  provider.userSettings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
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
                      AppLocalizations.get('darkMode'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.userSettings.isDarkMode ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: provider.userSettings.isDarkMode,
                  onChanged: (value) {
                    final newSettings = UserSettings(
                      dailyGoal: provider.userSettings.dailyGoal,
                      reminderInterval: provider.userSettings.reminderInterval,
                      reminderStartTime: provider.userSettings.reminderStartTime,
                      reminderEndTime: provider.userSettings.reminderEndTime,
                      defaultAmount: provider.userSettings.defaultAmount,
                      isDarkMode: value,
                      language: provider.userSettings.language,
                      notificationsEnabled: provider.userSettings.notificationsEnabled,
                      persistentNotificationEnabled: provider.userSettings.persistentNotificationEnabled,
                      customDrinks: provider.userSettings.customDrinks,
                      waterReminders: provider.userSettings.waterReminders,
                    );
                    provider.updateSettings(newSettings);
                  },
                  activeColor: const Color(0xFF9C27B0),
                  activeTrackColor: const Color(0xFF9C27B0).withOpacity(0.3),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPersistentNotificationItem(BuildContext context, WaterIntakeProvider provider) {
    return FadeTransition(
      opacity: _itemAnimations[4],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(_itemAnimations[4]),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF42A5F5).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notification_important,
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
                      AppLocalizations.get('statusBarNotifications'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.userSettings.persistentNotificationEnabled 
                          ? AppLocalizations.get('statusBarNotificationsOn')
                          : AppLocalizations.get('statusBarNotificationsOff'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: provider.userSettings.persistentNotificationEnabled,
                  onChanged: (value) {
                    final newSettings = UserSettings(
                      dailyGoal: provider.userSettings.dailyGoal,
                      reminderInterval: provider.userSettings.reminderInterval,
                      reminderStartTime: provider.userSettings.reminderStartTime,
                      reminderEndTime: provider.userSettings.reminderEndTime,
                      defaultAmount: provider.userSettings.defaultAmount,
                      isDarkMode: provider.userSettings.isDarkMode,
                      language: provider.userSettings.language,
                      notificationsEnabled: provider.userSettings.notificationsEnabled,
                      persistentNotificationEnabled: value,
                      customDrinks: provider.userSettings.customDrinks,
                      waterReminders: provider.userSettings.waterReminders,
                    );
                    provider.updateSettings(newSettings);
                  },
                  activeColor: const Color(0xFF42A5F5),
                  activeTrackColor: const Color(0xFF42A5F5).withOpacity(0.3),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}