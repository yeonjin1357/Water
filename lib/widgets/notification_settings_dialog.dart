import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_intake_provider.dart';
import '../models/user_settings.dart';
import '../localization/app_localizations.dart';
import '../services/notification_service.dart';
import 'reminder_edit_dialog.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late List<WaterReminder> _reminders;
  bool _canScheduleExactAlarms = true;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    
    final provider = context.read<WaterIntakeProvider>();
    _reminders = List.from(provider.userSettings.waterReminders);
    
    // Check exact alarm permission
    _checkExactAlarmPermission();
  }
  
  Future<void> _checkExactAlarmPermission() async {
    final notificationService = NotificationService();
    final canSchedule = await notificationService.canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _canScheduleExactAlarms = canSchedule;
      });
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  Future<void> _saveSettings() async {
    final provider = context.read<WaterIntakeProvider>();
    final notificationService = NotificationService();
    
    final newSettings = UserSettings(
      dailyGoal: provider.userSettings.dailyGoal,
      reminderInterval: provider.userSettings.reminderInterval,
      reminderStartTime: provider.userSettings.reminderStartTime,
      reminderEndTime: provider.userSettings.reminderEndTime,
      defaultAmount: provider.userSettings.defaultAmount,
      isDarkMode: provider.userSettings.isDarkMode,
      language: provider.userSettings.language,
      notificationsEnabled: _reminders.isNotEmpty,
      persistentNotificationEnabled: provider.userSettings.persistentNotificationEnabled,
      customDrinks: provider.userSettings.customDrinks,
      waterReminders: _reminders,
    );
    
    await provider.updateSettings(newSettings);
    
    // 알림 스케줄링
    if (_reminders.isNotEmpty) {
      await notificationService.scheduleWaterReminderNotifications(_reminders);
    } else {
      await notificationService.cancelWaterReminders();
    }
    
    // 상태바 알림이 켜져있으면 재설정
    if (provider.userSettings.persistentNotificationEnabled) {
      await notificationService.showPersistentNotification(
        currentAmount: provider.todayTotal,
        dailyGoal: provider.userSettings.dailyGoal,
      );
    }
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _reminders.isEmpty ? AppLocalizations.get('allNotificationsDisabled') : AppLocalizations.get('notificationSaved')
          ),
          backgroundColor: const Color(0xFF42A5F5),
        ),
      );
    }
  }
  
  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) => ReminderEditDialog(
        onSave: (reminder) {
          setState(() {
            _reminders.add(reminder);
          });
        },
      ),
    );
  }
  
  void _editReminder(WaterReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => ReminderEditDialog(
        reminder: reminder,
        onSave: (updatedReminder) {
          setState(() {
            final index = _reminders.indexWhere((r) => r.id == reminder.id);
            if (index != -1) {
              _reminders[index] = updatedReminder;
            }
          });
        },
      ),
    );
  }
  
  void _deleteReminder(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(AppLocalizations.get('deleteNotification')),
        content: Text(AppLocalizations.get('deleteNotificationConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _reminders.removeWhere((r) => r.id == id);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.get('delete')),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
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
            children: [
              _buildHeader(context),
              if (!_canScheduleExactAlarms) _buildPermissionWarning(context),
              Expanded(
                child: _reminders.isEmpty
                    ? _buildEmptyState(context)
                    : _buildRemindersList(context),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPermissionWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('exactAlarmPermission'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.get('exactAlarmPermissionDesc'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final notificationService = NotificationService();
              await notificationService.openAlarmPermissionSettings();
              // 설정에서 돌아온 후 권한 재확인
              Future.delayed(const Duration(seconds: 1), () {
                _checkExactAlarmPermission();
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.orange.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.get('permissionSettings'),
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('notificationSettings'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.get('notificationCount', _reminders.length.toString()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // 알림 테스트 메뉴 (디버깅용 - 개발 시 주석 해제하여 사용)
          // PopupMenuButton을 통해 다양한 알림 테스트 가능:
          // - 즉시 알림 테스트
          // - 10초 후 예약 알림 테스트  
          // - 1분 후 예약 알림 테스트
          // - 주기적 알림 테스트
          // - 모든 알림 제거
          // - 알림 권한 확인
          /*
          PopupMenuButton<String>(
            onSelected: (value) async {
              final notificationService = NotificationService();
              if (value == 'instant') {
                await notificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('testNotificationSent')),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else if (value == 'scheduled') {
                await notificationService.scheduleTestNotificationIn10Seconds();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('testNotificationScheduled10s')),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } else if (value == 'clear_all') {
                await notificationService.clearAllAndReset();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('allNotificationsCleared')),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (value == 'check_permission') {
                final canSchedule = await notificationService.canScheduleExactAlarms();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(canSchedule 
                          ? AppLocalizations.get('permissionGranted') 
                          : AppLocalizations.get('permissionDenied')),
                      duration: const Duration(seconds: 3),
                      backgroundColor: canSchedule ? Colors.green : Colors.orange,
                    ),
                  );
                }
              } else if (value == 'periodic') {
                await notificationService.scheduleSimpleTest();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('periodicTestStarted')),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              } else if (value == '1min') {
                await notificationService.scheduleTestNotificationIn1Minute();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.get('testNotificationScheduled1m')),
                      duration: Duration(seconds: 3),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'instant',
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('instantTest')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scheduled',
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('scheduledTest10s')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: '1min',
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('scheduledTest1m')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'periodic',
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 18, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('periodicTest')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('clearAllNotifications')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'check_permission',
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('checkPermission')),
                  ],
                ),
              ),
            ],
            icon: const Icon(
              Icons.bug_report,
              color: Colors.orange,
              size: 20,
            ),
          ),
          */
          IconButton(
            onPressed: _addReminder,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF42A5F5),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('noNotifications'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.get('addNotificationHint'),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRemindersList(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _reminders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reminder = _reminders[index];
              return _buildReminderItem(context, reminder);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.get('swipeDeleteHint'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReminderItem(BuildContext context, WaterReminder reminder) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
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
            title: Text(AppLocalizations.get('deleteNotification')),
            content: Text(AppLocalizations.get('deleteNotificationConfirm')),
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
      onDismissed: (direction) {
        setState(() {
          _reminders.removeWhere((r) => r.id == reminder.id);
        });
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editReminder(reminder),
          onLongPress: () {
            // 길게 누르면 삭제 옵션 표시
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Color(0xFF42A5F5)),
                      title: Text(AppLocalizations.get('editNotification')),
                      onTap: () {
                        Navigator.pop(context);
                        _editReminder(reminder);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text(AppLocalizations.get('deleteNotification')),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteReminder(reminder.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: reminder.isEnabled
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: reminder.isEnabled
                          ? [const Color(0xFF66BB6A), const Color(0xFF4CAF50)]
                          : [Colors.grey.shade400, Colors.grey.shade500],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(reminder.time),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reminder.label.isNotEmpty) ...[
                        Text(
                          reminder.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        reminder.getWeekdaysText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (value) {
                    setState(() {
                      final index = _reminders.indexWhere((r) => r.id == reminder.id);
                      if (index != -1) {
                        _reminders[index] = WaterReminder(
                          id: reminder.id,
                          time: reminder.time,
                          weekdays: reminder.weekdays,
                          isEnabled: value,
                          label: reminder.label,
                        );
                      }
                    });
                  },
                  activeColor: const Color(0xFF4CAF50),
                  activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
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
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  AppLocalizations.get('save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}