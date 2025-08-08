import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/water_intake_provider.dart';
import '../models/water_intake.dart';
import '../services/database_helper.dart';
import '../localization/app_localizations.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isBarChart = true;
  bool _isHydrateBarChart = false;
  Map<String, int> _weeklyData = {};
  Map<String, int> _monthlyData = {};
  Map<String, int> _yearlyData = {};
  Map<String, int> _drinkTypeData = {};
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<WaterIntakeProvider>();
    
    if (_selectedTabIndex == 0) {
      // Weekly view - get data for the selected week
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      _weeklyData = {};
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = date.toString().split(' ')[0];
        final total = await DatabaseHelper().getTotalForDate(date);
        _weeklyData[dateKey] = total;
      }
      
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      _drinkTypeData = await provider.getDrinkTypeStats(startOfWeek, endOfWeek);
    } else if (_selectedTabIndex == 1) {
      // Monthly view - group by weeks
      _monthlyData = {};
      final year = _selectedDate.year;
      final month = _selectedDate.month;
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      
      // Calculate week data
      for (int week = 0; week < 5; week++) {
        int weekTotal = 0;
        int dayCount = 0;
        
        for (int day = week * 7 + 1; day <= lastDay.day && day <= (week + 1) * 7; day++) {
          final date = DateTime(year, month, day);
          final total = await DatabaseHelper().getTotalForDate(date);
          weekTotal += total;
          if (total > 0) dayCount++;
        }
        
        // Store weekly average
        final weekKey = 'week_$week';
        _monthlyData[weekKey] = dayCount > 0 ? (weekTotal / dayCount).round() : 0;
      }
      
      _drinkTypeData = await provider.getDrinkTypeStats(firstDay, lastDay);
    } else {
      // Yearly view - group by months
      _yearlyData = {};
      final year = _selectedDate.year;
      
      for (int month = 1; month <= 12; month++) {
        int monthTotal = 0;
        int dayCount = 0;
        final firstDay = DateTime(year, month, 1);
        final lastDay = DateTime(year, month + 1, 0);
        
        for (int day = 1; day <= lastDay.day; day++) {
          final date = DateTime(year, month, day);
          final total = await DatabaseHelper().getTotalForDate(date);
          monthTotal += total;
          if (total > 0) dayCount++;
        }
        
        // Store monthly average
        final monthKey = 'month_${month - 1}';
        _yearlyData[monthKey] = dayCount > 0 ? (monthTotal / dayCount).round() : 0;
      }
      
      final firstDay = DateTime(year, 1, 1);
      final lastDay = DateTime(year, 12, 31);
      _drinkTypeData = await provider.getDrinkTypeStats(firstDay, lastDay);
    }
    
    _streakDays = await provider.getStreakDays();
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                AppLocalizations.get('report'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildTabBar(),
            _buildDateSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDrinkCompletionCard(),
                  const SizedBox(height: 16),
                  _buildHydrateCard(),
                  const SizedBox(height: 16),
                  _buildDrinkTypesCard(),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [AppLocalizations.get('weekly'), AppLocalizations.get('monthly'), AppLocalizations.get('yearly')];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4FC3F7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateSelector() {
    String dateText;
    bool canGoForward = false;
    final now = DateTime.now();
    
    if (_selectedTabIndex == 0) {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateText = '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
      // Check if next week would be in the future
      final nextWeekStart = startOfWeek.add(const Duration(days: 7));
      canGoForward = !nextWeekStart.isAfter(now);
    } else if (_selectedTabIndex == 1) {
      dateText = DateFormat('MMMM yyyy').format(_selectedDate);
      // Check if next month would be in the future
      final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1);
      canGoForward = !(nextMonth.year > now.year || (nextMonth.year == now.year && nextMonth.month > now.month));
    } else {
      dateText = DateFormat('yyyy').format(_selectedDate);
      // Check if next year would be in the future
      canGoForward = _selectedDate.year < now.year;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              setState(() {
                if (_selectedTabIndex == 0) {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                } else if (_selectedTabIndex == 1) {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                } else {
                  _selectedDate = DateTime(_selectedDate.year - 1);
                }
              });
              _loadData();
            },
          ),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: canGoForward ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            onPressed: canGoForward ? () {
              setState(() {
                if (_selectedTabIndex == 0) {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                } else if (_selectedTabIndex == 1) {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                } else {
                  _selectedDate = DateTime(_selectedDate.year + 1);
                }
              });
              _loadData();
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.get('drinkCompletion'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart,
                      color: _isBarChart ? const Color(0xFF4FC3F7) : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isBarChart = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.show_chart,
                      color: !_isBarChart ? const Color(0xFF4FC3F7) : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isBarChart = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _isBarChart ? _buildBarChart() : _buildCompletionLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.get('hydrate'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart,
                      color: _isHydrateBarChart ? const Color(0xFF4FC3F7) : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isHydrateBarChart = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.show_chart,
                      color: !_isHydrateBarChart ? const Color(0xFF4FC3F7) : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isHydrateBarChart = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _isHydrateBarChart ? _buildHydrateBarChart() : _buildHydrateLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkTypesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drink Types',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: _buildPieChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDrinkTypeLegend(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final provider = context.read<WaterIntakeProvider>();
    final dailyGoal = provider.userSettings.dailyGoal;
    
    List<BarChartGroupData> barGroups = [];
    
    if (_selectedTabIndex == 0) {
      // Weekly view
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = date.toString().split(' ')[0];
        final amount = _weeklyData[dateKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: percentage.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    } else if (_selectedTabIndex == 1) {
      // Monthly view - show weeks
      for (int i = 0; i < 5; i++) {
        final weekKey = 'week_$i';
        final amount = _monthlyData[weekKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: percentage.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    } else {
      // Yearly view - show months
      for (int i = 0; i < 12; i++) {
        final monthKey = 'month_$i';
        final amount = _yearlyData[monthKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: percentage.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final percentage = rod.toY.toInt();
              return BarTooltipItem(
                '$percentage%',
                TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
            tooltipRoundedRadius: 12,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (_selectedTabIndex == 0) {
                  // Weekly view - show day numbers
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                    final date = startOfWeek.add(Duration(days: value.toInt()));
                    return Text(
                      date.day.toString(),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else if (_selectedTabIndex == 1) {
                  // Monthly view - show week labels
                  if (value.toInt() >= 0 && value.toInt() < 5) {
                    return Text(
                      '${AppLocalizations.get('week').substring(0, 1)}${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else {
                  // Yearly view - show month labels
                  if (value.toInt() >= 0 && value.toInt() < 12) {
                    return Text(
                      AppLocalizations.getMonthName(value.toInt() + 1),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                );
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildCompletionLineChart() {
    final provider = context.read<WaterIntakeProvider>();
    final dailyGoal = provider.userSettings.dailyGoal;
    
    List<FlSpot> spots = [];
    
    if (_selectedTabIndex == 0) {
      // Weekly view
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = date.toString().split(' ')[0];
        final amount = _weeklyData[dateKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        spots.add(FlSpot(i.toDouble(), percentage.toDouble()));
      }
    } else if (_selectedTabIndex == 1) {
      // Monthly view - show weeks
      for (int i = 0; i < 5; i++) {
        final weekKey = 'week_$i';
        final amount = _monthlyData[weekKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        spots.add(FlSpot(i.toDouble(), percentage.toDouble()));
      }
    } else {
      // Yearly view - show months
      for (int i = 0; i < 12; i++) {
        final monthKey = 'month_$i';
        final amount = _yearlyData[monthKey] ?? 0;
        final percentage = dailyGoal > 0 ? (amount / dailyGoal * 100).clamp(0, 100) : 0;
        
        spots.add(FlSpot(i.toDouble(), percentage.toDouble()));
      }
    }
    
    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0)];
    }
    
    return LineChart(
      LineChartData(
        maxY: 100,
        minY: 0,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final percentage = touchedSpot.y.toInt();
                return LineTooltipItem(
                  '$percentage%',
                  TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
            tooltipRoundedRadius: 12,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (_selectedTabIndex == 0) {
                  // Weekly view - show day numbers
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                    final date = startOfWeek.add(Duration(days: value.toInt()));
                    return Text(
                      date.day.toString(),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else if (_selectedTabIndex == 1) {
                  // Monthly view - show week labels
                  if (value.toInt() >= 0 && value.toInt() < 5) {
                    return Text(
                      '${AppLocalizations.get('week').substring(0, 1)}${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else {
                  // Yearly view - show month labels
                  if (value.toInt() >= 0 && value.toInt() < 12) {
                    return Text(
                      AppLocalizations.getMonthName(value.toInt() + 1),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                );
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF4FC3F7),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4FC3F7).withOpacity(0.3),
                  const Color(0xFF29B6F6).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrateBarChart() {
    final provider = context.read<WaterIntakeProvider>();
    final dailyGoal = provider.userSettings.dailyGoal;
    
    List<BarChartGroupData> barGroups = [];
    double maxValue = 0;
    
    if (_selectedTabIndex == 0) {
      // Weekly view
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = date.toString().split(' ')[0];
        final amount = _weeklyData[dateKey] ?? 0;
        
        if (amount > maxValue) maxValue = amount.toDouble();
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: amount.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    } else if (_selectedTabIndex == 1) {
      // Monthly view - show weeks
      for (int i = 0; i < 5; i++) {
        final weekKey = 'week_$i';
        final amount = _monthlyData[weekKey] ?? 0;
        
        if (amount > maxValue) maxValue = amount.toDouble();
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: amount.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    } else {
      // Yearly view - show months
      for (int i = 0; i < 12; i++) {
        final monthKey = 'month_$i';
        final amount = _yearlyData[monthKey] ?? 0;
        
        if (amount > maxValue) maxValue = amount.toDouble();
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: amount.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedTabIndex == 2 ? 16 : 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        );
      }
    }
    
    // Calculate dynamic max Y based on data
    double chartMaxY = maxValue * 1.2; // 20% higher than max value
    if (chartMaxY < 500) chartMaxY = 500; // Minimum 500ml
    chartMaxY = (chartMaxY / 500).ceilToDouble() * 500; // Round up to nearest 500ml
    
    // Calculate interval for Y axis labels
    double interval = chartMaxY / 5; // Show 5 labels
    interval = (interval / 100).ceilToDouble() * 100; // Round to nearest 100
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final amount = rod.toY.toInt();
              return BarTooltipItem(
                '${amount}ml',
                TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
            tooltipRoundedRadius: 12,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (_selectedTabIndex == 0) {
                  // Weekly view - show day numbers
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                    final date = startOfWeek.add(Duration(days: value.toInt()));
                    return Text(
                      date.day.toString(),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else if (_selectedTabIndex == 1) {
                  // Monthly view - show week labels
                  if (value.toInt() >= 0 && value.toInt() < 5) {
                    return Text(
                      '${AppLocalizations.get('week').substring(0, 1)}${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else {
                  // Yearly view - show month labels
                  if (value.toInt() >= 0 && value.toInt() < 12) {
                    return Text(
                      AppLocalizations.getMonthName(value.toInt() + 1),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('0', style: TextStyle(fontSize: 10, color: Colors.black54));
                } else {
                  final liters = value / 1000;
                  if (liters == liters.toInt()) {
                    return Text('${liters.toInt()}L', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)));
                  } else {
                    return Text('${liters.toStringAsFixed(1)}L', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)));
                  }
                }
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildHydrateLineChart() {
    final provider = context.read<WaterIntakeProvider>();
    final dailyGoal = provider.userSettings.dailyGoal;
    
    List<FlSpot> spots = [];
    double maxValue = 0;
    
    if (_selectedTabIndex == 0) {
      // Weekly view
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = date.toString().split(' ')[0];
        final amount = _weeklyData[dateKey] ?? 0;
        
        spots.add(FlSpot(i.toDouble(), amount.toDouble()));
        if (amount > maxValue) maxValue = amount.toDouble();
      }
    } else if (_selectedTabIndex == 1) {
      // Monthly view - show weeks
      for (int i = 0; i < 5; i++) {
        final weekKey = 'week_$i';
        final amount = _monthlyData[weekKey] ?? 0;
        
        spots.add(FlSpot(i.toDouble(), amount.toDouble()));
        if (amount > maxValue) maxValue = amount.toDouble();
      }
    } else {
      // Yearly view - show months
      for (int i = 0; i < 12; i++) {
        final monthKey = 'month_$i';
        final amount = _yearlyData[monthKey] ?? 0;
        
        spots.add(FlSpot(i.toDouble(), amount.toDouble()));
        if (amount > maxValue) maxValue = amount.toDouble();
      }
    }
    
    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0)];
    }
    
    // Calculate dynamic max Y based on data
    double chartMaxY = maxValue * 1.2; // 20% higher than max value
    if (chartMaxY < 500) chartMaxY = 500; // Minimum 500ml
    chartMaxY = (chartMaxY / 500).ceilToDouble() * 500; // Round up to nearest 500ml
    
    // Calculate interval for Y axis labels
    double interval = chartMaxY / 5; // Show 5 labels
    interval = (interval / 100).ceilToDouble() * 100; // Round to nearest 100
    
    return LineChart(
      LineChartData(
        maxY: chartMaxY,
        minY: 0,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final amount = touchedSpot.y.toInt();
                return LineTooltipItem(
                  '${amount}ml',
                  TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
            tooltipRoundedRadius: 12,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (_selectedTabIndex == 0) {
                  // Weekly view - show day numbers
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                    final date = startOfWeek.add(Duration(days: value.toInt()));
                    return Text(
                      date.day.toString(),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else if (_selectedTabIndex == 1) {
                  // Monthly view - show week labels
                  if (value.toInt() >= 0 && value.toInt() < 5) {
                    return Text(
                      '${AppLocalizations.get('week').substring(0, 1)}${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                } else {
                  // Yearly view - show month labels
                  if (value.toInt() >= 0 && value.toInt() < 12) {
                    return Text(
                      AppLocalizations.getMonthName(value.toInt() + 1),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('0', style: TextStyle(fontSize: 10, color: Colors.black54));
                } else {
                  final liters = value / 1000;
                  if (liters == liters.toInt()) {
                    return Text('${liters.toInt()}L', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)));
                  } else {
                    return Text('${liters.toStringAsFixed(1)}L', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)));
                  }
                }
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF4FC3F7),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4FC3F7).withOpacity(0.3),
                  const Color(0xFF29B6F6).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _drinkTypeData.values.fold<int>(0, (sum, value) => sum + value);
    
    if (total == 0) {
      return PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.grey.shade300,
              value: 100,
              title: 'No data',
              radius: 30,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    final drinkColors = {
      'water': const Color(0xFF4FC3F7),
      'juice': const Color(0xFFFF9800),
      'coffee': const Color(0xFF8BC34A),
      'milk': const Color(0xFF9C27B0),
      'tea': const Color(0xFFE91E63),
    };
    
    List<PieChartSectionData> sections = [];
    
    _drinkTypeData.forEach((type, amount) {
      if (amount > 0) {
        final percentage = (amount / total * 100).round();
        sections.add(
          PieChartSectionData(
            color: drinkColors[type.toLowerCase()] ?? const Color(0xFF607D8B),
            value: amount.toDouble(),
            title: '$percentage%',
            radius: 30,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  Widget _buildDrinkTypeLegend() {
    final total = _drinkTypeData.values.fold<int>(0, (sum, value) => sum + value);
    
    final drinkColors = {
      'water': const Color(0xFF4FC3F7),
      'juice': const Color(0xFFFF9800),
      'coffee': const Color(0xFF8BC34A),
      'milk': const Color(0xFF9C27B0),
      'tea': const Color(0xFFE91E63),
    };
    
    List<Map<String, dynamic>> drinkTypes = [];
    
    _drinkTypeData.forEach((type, amount) {
      if (amount > 0) {
        final percentage = total > 0 ? (amount / total * 100).round() : 0;
        drinkTypes.add({
          'name': type[0].toUpperCase() + type.substring(1),
          'percent': '$percentage%',
          'color': drinkColors[type.toLowerCase()] ?? const Color(0xFF607D8B),
        });
      }
    });
    
    if (drinkTypes.isEmpty) {
      drinkTypes = [
        {'name': 'No data', 'percent': '0%', 'color': Colors.grey.shade300},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: drinkTypes.map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: type['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${type['name']} (${type['percent']})',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}