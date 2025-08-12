import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/water_intake_provider.dart';
import '../localization/app_localizations.dart';

class CalendarWithGauge extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;

  const CalendarWithGauge({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarWithGauge> createState() => _CalendarWithGaugeState();
}

class _CalendarWithGaugeState extends State<CalendarWithGauge> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  Map<DateTime, double> _monthlyProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = widget.initialDate ?? DateTime.now();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<WaterIntakeProvider>();

    // 한 번에 한 달치 진행률 데이터 가져오기
    final progress = await provider.getMonthlyProgress(
      _currentMonth.year,
      _currentMonth.month,
    );

    setState(() {
      _monthlyProgress = progress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAliasWithSaveLayer, // 그림자가 border-radius를 따라가도록
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Column이 필요한 만큼만 공간 차지
          children: [
            _buildHeader(),
            _buildWeekDayLabels(),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildCalendarGrid(),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
                _loadMonthData();
              });
            },
          ),
          Column(
            children: [
              Text(
                AppLocalizations.currentLanguage == 'ko'
                    ? '${_currentMonth.year}년 ${_currentMonth.month}월'
                    : DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentMonth.isBefore(
                  DateTime(DateTime.now().year, DateTime.now().month),
                )
                ? () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                      _loadMonthData();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayLabels() {
    final weekDays = AppLocalizations.currentLanguage == 'en'
        ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((day) {
          final isWeekend = day == weekDays[0] || day == weekDays[6];
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? Colors.red.withOpacity(0.6)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    List<List<Widget>> weeks = [];
    List<Widget> currentWeek = [];

    // 빈 공간 추가
    for (int i = 0; i < startWeekday; i++) {
      currentWeek.add(const Expanded(child: SizedBox()));
    }

    // 날짜 추가
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final progress = _monthlyProgress[date] ?? 0.0;
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = _isToday(date);
      final isFuture = date.isAfter(DateTime.now());

      currentWeek.add(
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      widget.onDateSelected(date);
                      Navigator.of(context).pop();
                    },
              child: Container(
                margin: const EdgeInsets.all(2),
                child: CustomPaint(
                  painter: _CircularGaugePainter(
                    progress: isFuture ? 0 : progress,
                    isSelected: isSelected,
                    isToday: isToday,
                    isFuture: isFuture,
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday || isSelected || progress >= 1.0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isFuture
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3)
                            : isSelected
                            ? Colors.white
                            : isToday
                            ? const Color(0xFF42A5F5)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 주 완성 확인
      if ((startWeekday + day) % 7 == 0 || day == lastDay.day) {
        // 남은 빈 공간 채우기
        while (currentWeek.length < 7) {
          currentWeek.add(const Expanded(child: SizedBox()));
        }
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: weeks
            .map(
              (week) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: week,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerLowest.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(const Color(0xFF00C853), '100%'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFF2196F3), '70%'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFFFFA726), '40%'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFFEF5350), '<40%'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool isDarkMode;

  _CircularGaugePainter({
    required this.progress,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3; // 날짜 숫자를 감싸는 원

    // 선택된 날짜 스타일
    if (isSelected) {
      final bgPaint = Paint()
        ..color = const Color(0xFF42A5F5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);
    }
    // 미래가 아닌 모든 날짜에 달성률 게이지 표시
    else if (!isFuture) {
      // 배경 트랙 (연한 회색 원)
      final trackPaint = Paint()
        ..color = isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, trackPaint);

      // 진행률 원호
      if (progress > 0) {
        // 모든 날짜에 달성률에 따른 색상 적용
        final progressColor = _getProgressColor(progress);

        final progressPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = (progress >= 1.0 || isToday) ? 2.5 : 2
          ..strokeCap = StrokeCap.round;

        final rect = Rect.fromCircle(center: center, radius: radius);
        const startAngle = -90 * (3.141592653589793 / 180); // 12시 방향부터 시작
        final sweepAngle =
            progress.clamp(0.0, 1.0) * 2 * 3.141592653589793; // progress 비율만큼

        canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
      }
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return const Color(0xFF00C853); // 초록색 (100% 이상)
    } else if (progress >= 0.7) {
      return const Color(0xFF2196F3); // 파란색 (70% 이상)
    } else if (progress >= 0.4) {
      return const Color(0xFFFFA726); // 주황색 (40% 이상)
    } else if (progress > 0) {
      return const Color(0xFFEF5350); // 빨간색 (40% 미만)
    } else {
      return Colors.transparent; // 0%인 경우 테두리 없음
    }
  }

  @override
  bool shouldRepaint(_CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isToday != isToday;
  }
}
