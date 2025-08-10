import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../localization/app_localizations.dart';

class ReminderEditDialog extends StatefulWidget {
  final WaterReminder? reminder;
  final Function(WaterReminder) onSave;

  const ReminderEditDialog({super.key, this.reminder, required this.onSave});

  @override
  State<ReminderEditDialog> createState() => _ReminderEditDialogState();
}

class _ReminderEditDialogState extends State<ReminderEditDialog>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _selectedTime;
  late List<int> _selectedWeekdays;
  late TextEditingController _labelController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late List<String> _weekdayNames;

  @override
  void initState() {
    super.initState();
    _weekdayNames = [
      AppLocalizations.get('monday'),
      AppLocalizations.get('tuesday'),
      AppLocalizations.get('wednesday'),
      AppLocalizations.get('thursday'),
      AppLocalizations.get('friday'),
      AppLocalizations.get('saturday'),
      AppLocalizations.get('sunday'),
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    if (widget.reminder != null) {
      _selectedTime = widget.reminder!.time;
      _selectedWeekdays = List.from(widget.reminder!.weekdays);
      _labelController = TextEditingController(text: widget.reminder!.label);
    } else {
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _selectedWeekdays = [1, 2, 3, 4, 5]; // 평일 기본 선택
      _labelController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              dialHandColor: const Color(0xFF42A5F5),
              dialBackgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              hourMinuteTextStyle: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
        _selectedWeekdays.sort();
      }
    });
  }

  void _toggleWeekdayGroup(String group) {
    setState(() {
      if (group == 'all') {
        if (_selectedWeekdays.length == 7) {
          _selectedWeekdays.clear();
        } else {
          _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
        }
      } else if (group == 'weekdays') {
        final weekdays = [1, 2, 3, 4, 5];
        if (weekdays.every((day) => _selectedWeekdays.contains(day))) {
          _selectedWeekdays.removeWhere((day) => weekdays.contains(day));
        } else {
          _selectedWeekdays.addAll(
            weekdays.where((day) => !_selectedWeekdays.contains(day)),
          );
          _selectedWeekdays.sort();
        }
      } else if (group == 'weekend') {
        final weekend = [6, 7];
        if (weekend.every((day) => _selectedWeekdays.contains(day))) {
          _selectedWeekdays.removeWhere((day) => weekend.contains(day));
        } else {
          _selectedWeekdays.addAll(
            weekend.where((day) => !_selectedWeekdays.contains(day)),
          );
          _selectedWeekdays.sort();
        }
      }
    });
  }

  void _save() {
    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.get('selectOneDay')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reminder = WaterReminder(
      id:
          widget.reminder?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      weekdays: _selectedWeekdays,
      isEnabled: widget.reminder?.isEnabled ?? true,
      label: _labelController.text.trim(),
    );

    widget.onSave(reminder);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      _buildTimeSection(context),
                      const SizedBox(height: 28),
                      _buildWeekdaySection(context),
                      const SizedBox(height: 28),
                      _buildLabelSection(context),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF42A5F5).withOpacity(0.1),
            const Color(0xFF2196F3).withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.alarm_add, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reminder != null
                      ? AppLocalizations.get('editNotification')
                      : AppLocalizations.get('addNotification'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reminder != null
                      ? _formatTime(_selectedTime)
                      : AppLocalizations.get('time'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 12),
          child: Text(
            AppLocalizations.get('time'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF42A5F5).withOpacity(0.08),
                    const Color(0xFF2196F3).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: Color(0xFF42A5F5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(_selectedTime),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1976D2),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          AppLocalizations.get('tapToChange'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    color: const Color(0xFF42A5F5).withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            AppLocalizations.get('repeatDays'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickSelectChip(AppLocalizations.get('everyday'), 'all'),
            _buildQuickSelectChip(AppLocalizations.get('weekdays'), 'weekdays'),
            _buildQuickSelectChip(AppLocalizations.get('weekend'), 'weekend'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final isSelected = _selectedWeekdays.contains(weekday);
            return Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: index == 0 || index == 6 ? 0 : 2),
                child: GestureDetector(
                  onTap: () => _toggleWeekday(weekday),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Theme.of(context).colorScheme.surfaceContainerHighest
                                .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Theme.of(context).dividerColor.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF42A5F5).withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          _weekdayNames[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, String group) {
    bool isSelected = false;
    if (group == 'all') {
      isSelected = _selectedWeekdays.length == 7;
    } else if (group == 'weekdays') {
      isSelected = [
        1,
        2,
        3,
        4,
        5,
      ].every((day) => _selectedWeekdays.contains(day));
    } else if (group == 'weekend') {
      isSelected = [6, 7].every((day) => _selectedWeekdays.contains(day));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleWeekdayGroup(group),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFF42A5F5).withOpacity(0.15),
                      const Color(0xFF2196F3).withOpacity(0.1),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF42A5F5).withOpacity(0.5)
                  : Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF1976D2)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            AppLocalizations.get('labelOptional'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _labelController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: AppLocalizations.get('labelHint'),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF42A5F5),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            prefixIcon: Icon(
              Icons.label_outline,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              AppLocalizations.get('cancel'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.reminder != null ? Icons.check : Icons.add,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.reminder != null
                        ? AppLocalizations.get('save')
                        : AppLocalizations.get('add'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
