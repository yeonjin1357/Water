import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../models/user_settings.dart';
import '../localization/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showLanguageDialog(BuildContext context, WaterIntakeProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.get('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('한국어'),
                value: 'ko',
                groupValue: provider.userSettings.language,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = UserSettings(
                      dailyGoal: provider.userSettings.dailyGoal,
                      reminderInterval: provider.userSettings.reminderInterval,
                      reminderStartTime: provider.userSettings.reminderStartTime,
                      reminderEndTime: provider.userSettings.reminderEndTime,
                      defaultAmount: provider.userSettings.defaultAmount,
                      isDarkMode: provider.userSettings.isDarkMode,
                      language: value,
                    );
                    provider.updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: provider.userSettings.language,
                onChanged: (value) {
                  if (value != null) {
                    final newSettings = UserSettings(
                      dailyGoal: provider.userSettings.dailyGoal,
                      reminderInterval: provider.userSettings.reminderInterval,
                      reminderStartTime: provider.userSettings.reminderStartTime,
                      reminderEndTime: provider.userSettings.reminderEndTime,
                      defaultAmount: provider.userSettings.defaultAmount,
                      isDarkMode: provider.userSettings.isDarkMode,
                      language: value,
                    );
                    provider.updateSettings(newSettings);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.get('cancel')),
            ),
          ],
        );
      },
    );
  }

  void _showDailyGoalDialog(BuildContext context, WaterIntakeProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.userSettings.dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.get('setDailyGoal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.get('enterDailyGoal')),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('goalAmount'),
                  border: const OutlineInputBorder(),
                  suffixText: 'ml',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.get('recommendedAmount'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.get('cancel')),
            ),
            ElevatedButton(
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
                  );
                  provider.updateSettings(newSettings);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('goalChanged', newGoal.toString())),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.get('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('settings')),
      ),
      body: Consumer<WaterIntakeProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              ListTile(
                title: Text(AppLocalizations.get('dailyGoal')),
                subtitle: Text('${provider.userSettings.dailyGoal} ml'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDailyGoalDialog(context, provider),
              ),
              SwitchListTile(
                title: Text(AppLocalizations.get('darkMode')),
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
                  );
                  provider.updateSettings(newSettings);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.get('language')),
                subtitle: Text(provider.userSettings.language == 'ko' ? '한국어' : 'English'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showLanguageDialog(context, provider),
              ),
              ListTile(
                title: Text(AppLocalizations.get('notifications')),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: 알림 설정 화면
                },
              ),
            ],
          );
        },
      ),
    );
  }
}