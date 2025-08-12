import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/water_intake.dart';
import '../providers/water_intake_provider.dart';
import '../localization/app_localizations.dart';

class HydrationTimeline extends StatefulWidget {
  const HydrationTimeline({super.key});

  @override
  State<HydrationTimeline> createState() => _HydrationTimelineState();
}

class _HydrationTimelineState extends State<HydrationTimeline> 
    with WidgetsBindingObserver {
  List<WaterIntake>? _selectedGroup;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 현재 시간으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
    
    // 매분마다 시간 업데이트
    _startTimer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때 시간 업데이트
      setState(() {
        _currentTime = DateTime.now();
      });
    }
  }

  void _startTimer() {
    // 5초마다 업데이트 (더 부드러운 현재 시간 마커 이동)
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final currentHourRatio = now.hour / 24.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      maxScroll * currentHourRatio,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterIntakeProvider>(
      builder: (context, provider, child) {
        final todayIntakes = provider.todayIntakes;
        final currentHour = _currentTime.hour + (_currentTime.minute / 60.0);

        return Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF252525),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8F9FA),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF42A5F5).withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF42A5F5).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.8),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.timeline,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.get('hydrationTimeline'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFF42A5F5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(_currentTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF42A5F5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: constraints.maxWidth * 2, // 스크롤 가능하도록 2배 너비
                          child: CustomPaint(
                            painter: _TimelinePainter(
                              intakes: todayIntakes,
                              currentHour: currentHour,
                              selectedGroup: _selectedGroup,
                              isDarkMode: Theme.of(context).brightness == Brightness.dark,
                            ),
                            child: GestureDetector(
                              onTapDown: (details) {
                                _handleTap(details.localPosition, constraints.maxWidth * 2, todayIntakes);
                              },
                              child: Container(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedGroup != null && _selectedGroup!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF42A5F5).withOpacity(0.1),
                          const Color(0xFF1E88E5).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedGroup!.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${_selectedGroup!.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42A5F5),
                              ),
                            ),
                          ),
                        Icon(
                          _getIntakeIcon(_selectedGroup!.first.drinkType),
                          size: 14,
                          color: const Color(0xFF42A5F5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedGroup!.length == 1
                              ? DateFormat('HH:mm').format(_selectedGroup!.first.timestamp)
                              : '${DateFormat('HH:mm').format(_selectedGroup!.first.timestamp)} - ${DateFormat('HH:mm').format(_selectedGroup!.last.timestamp)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 1,
                          height: 12,
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                        ),
                        Text(
                          '${_selectedGroup!.fold(0, (sum, intake) => sum + intake.amount)}ml',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPosition, double totalWidth, List<WaterIntake> intakes) {
    if (intakes.isEmpty) return;

    // 탭한 위치에서 가장 가까운 그룹 찾기 (패딩 고려)
    final timelineWidth = totalWidth - _TimelinePainter.leftPadding - _TimelinePainter.rightPadding;
    final adjustedX = localPosition.dx - _TimelinePainter.leftPadding;
    
    if (adjustedX < 0 || adjustedX > timelineWidth) return;
    
    final tapHour = (adjustedX / timelineWidth) * 24;
    
    // 30분 단위로 그룹핑된 데이터에서 찾기
    final groups = _groupIntakesByTime(intakes);
    
    double minDistance = double.infinity;
    List<WaterIntake>? selectedGroup;
    
    for (final group in groups) {
      final groupHour = group.first.timestamp.hour + (group.first.timestamp.minute / 60.0);
      final distance = (groupHour - tapHour).abs();
      
      if (distance < minDistance && distance < 0.5) {
        minDistance = distance;
        selectedGroup = group;
      }
    }
    
    setState(() {
      _selectedGroup = selectedGroup;
    });
  }
  
  List<List<WaterIntake>> _groupIntakesByTime(List<WaterIntake> intakes) {
    if (intakes.isEmpty) return [];
    
    List<List<WaterIntake>> groups = [];
    List<WaterIntake> currentGroup = [];
    
    for (final intake in intakes) {
      if (currentGroup.isEmpty) {
        currentGroup.add(intake);
      } else {
        final lastIntake = currentGroup.last;
        final timeDiff = intake.timestamp.difference(lastIntake.timestamp).inMinutes.abs();
        
        if (timeDiff <= 30) {
          currentGroup.add(intake);
        } else {
          groups.add(List.from(currentGroup));
          currentGroup = [intake];
        }
      }
    }
    
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }
    
    return groups;
  }

  IconData _getIntakeIcon(String drinkType) {
    switch (drinkType) {
      case 'water':
        return Icons.water_drop;
      case 'coffee':
        return Icons.coffee;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'juice':
        return Icons.local_drink;
      case 'milk':
        return Icons.breakfast_dining;
      default:
        return Icons.local_drink;
    }
  }
}

class _TimelinePainter extends CustomPainter {
  final List<WaterIntake> intakes;
  final double currentHour;
  final List<WaterIntake>? selectedGroup;
  final bool isDarkMode;
  
  static const double leftPadding = 15.0;
  static const double rightPadding = 15.0;

  _TimelinePainter({
    required this.intakes,
    required this.currentHour,
    this.selectedGroup,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // 배경 타임라인 그리기
    final timelinePaint = Paint()
      ..color = (isDarkMode ? Colors.white : const Color(0xFF42A5F5)).withOpacity(0.15)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    final timelineWidth = size.width - leftPadding - rightPadding;
    
    // 점선 효과를 위한 패턴
    double dashWidth = 5;
    double dashSpace = 3;
    double startX = leftPadding;
    
    while (startX < size.width - rightPadding) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(leftPadding, size.width - rightPadding), y),
        timelinePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 시간 마커 그리기 (4시간 간격)
    for (int hour = 0; hour <= 24; hour += 4) {
      final x = leftPadding + (hour / 24) * timelineWidth;
      
      // 시간 마커 원
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()
          ..color = (isDarkMode ? Colors.white : const Color(0xFF42A5F5)).withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );

      // 시간 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${hour}h',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: (isDarkMode ? Colors.white : const Color(0xFF42A5F5)).withOpacity(0.6),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      // 텍스트가 잘리지 않도록 위치 조정
      double textX = x - textPainter.width / 2;
      if (textX < 0) {
        textX = 2; // 왼쪽 여백
      } else if (textX + textPainter.width > size.width) {
        textX = size.width - textPainter.width - 2; // 오른쪽 여백
      }
      
      textPainter.paint(
        canvas,
        Offset(textX, y + 12),
      );
    }

    // 현재 시간 표시
    if (currentHour <= 24) {
      final currentX = leftPadding + (currentHour / 24) * timelineWidth;
      
      // 현재 시간 광원 효과
      final glowPaint = Paint()
        ..color = const Color(0xFFFF6B6B).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(
        Offset(currentX, y),
        8,
        glowPaint,
      );
      
      // 현재 시간 선
      paint
        ..color = const Color(0xFFFF6B6B)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(currentX, y - 12),
        Offset(currentX, y + 12),
        paint,
      );

      // 현재 시간 원
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white;
      canvas.drawCircle(
        Offset(currentX, y),
        5,
        paint,
      );
      
      paint.color = const Color(0xFFFF6B6B);
      canvas.drawCircle(
        Offset(currentX, y),
        3,
        paint,
      );
    }

    // 수분 섭취 마커를 그룹으로 그리기
    final groups = _groupIntakesByTime(intakes);
    
    for (final group in groups) {
      final firstIntake = group.first;
      final hour = firstIntake.timestamp.hour + (firstIntake.timestamp.minute / 60.0);
      final x = leftPadding + (hour / 24) * timelineWidth;
      
      // 그룹의 총 양
      final totalAmount = group.fold(0, (sum, intake) => sum + intake.amount);
      
      // 마커 크기 (양에 따라 조절, 그룹은 좀 더 크게)
      final baseRadius = group.length > 1 ? 6 : 4;
      final radius = baseRadius + (totalAmount / 200) * 2; // 200ml당 2픽셀 증가
      
      // 선택된 그룹 하이라이트
      final isSelected = selectedGroup != null && 
          selectedGroup!.isNotEmpty &&
          selectedGroup!.first.timestamp == group.first.timestamp;
      
      // 음료 종류에 따른 색상 (첫 번째 음료 기준)
      Color intakeColor;
      switch (firstIntake.drinkType) {
        case 'water':
          intakeColor = const Color(0xFF42A5F5);
          break;
        case 'coffee':
          intakeColor = const Color(0xFF795548);
          break;
        case 'tea':
          intakeColor = const Color(0xFF4CAF50);
          break;
        case 'juice':
          intakeColor = const Color(0xFFFF9800);
          break;
        case 'milk':
          intakeColor = const Color(0xFFF5F5F5);
          break;
        default:
          intakeColor = const Color(0xFF9E9E9E);
      }

      // 선택된 마커 광원 효과
      if (isSelected) {
        final glowPaint = Paint()
          ..color = intakeColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(
          Offset(x, y),
          radius + 6,
          glowPaint,
        );
      }
      
      // 그룹에 여러 개가 있으면 겹친 효과
      if (group.length > 1) {
        // 배경 원 (더 연한 색)
        paint
          ..color = intakeColor.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x + 2, y + 2),
          radius + 2,
          paint,
        );
      }
      
      // 마커 외곽선
      paint
        ..color = intakeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = group.length > 1 ? 2.5 : 2;
      
      canvas.drawCircle(
        Offset(x, y),
        radius.clamp(5, 14),
        paint,
      );
      
      // 마커 내부
      paint
        ..color = intakeColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        (radius - 1).clamp(3, 12),
        paint,
      );
      
      // 그룹 카운트 표시 (2개 이상일 때)
      if (group.length > 1) {
        final countText = '${group.length}';
        final textPainter = TextPainter(
          text: TextSpan(
            text: countText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        
        // 작은 원 배경
        paint
          ..color = const Color(0xFFFF6B6B)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x + radius * 0.7, y - radius * 0.7),
          7,
          paint,
        );
        
        textPainter.paint(
          canvas,
          Offset(x + radius * 0.7 - textPainter.width / 2, 
                 y - radius * 0.7 - textPainter.height / 2),
        );
      }
      
    }
  }
  
  List<List<WaterIntake>> _groupIntakesByTime(List<WaterIntake> intakes) {
    if (intakes.isEmpty) return [];
    
    List<List<WaterIntake>> groups = [];
    List<WaterIntake> currentGroup = [];
    
    for (final intake in intakes) {
      if (currentGroup.isEmpty) {
        currentGroup.add(intake);
      } else {
        final lastIntake = currentGroup.last;
        final timeDiff = intake.timestamp.difference(lastIntake.timestamp).inMinutes.abs();
        
        if (timeDiff <= 30) {
          currentGroup.add(intake);
        } else {
          groups.add(List.from(currentGroup));
          currentGroup = [intake];
        }
      }
    }
    
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }
    
    return groups;
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    // 리스트 길이나 내용이 변경되었는지 확인
    return oldDelegate.intakes.length != intakes.length ||
        oldDelegate.currentHour != currentHour ||
        oldDelegate.selectedGroup != selectedGroup ||
        oldDelegate.isDarkMode != isDarkMode ||
        !_areIntakeListsEqual(oldDelegate.intakes, intakes);
  }
  
  bool _areIntakeListsEqual(List<WaterIntake> list1, List<WaterIntake> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].timestamp != list2[i].timestamp ||
          list1[i].amount != list2[i].amount) {
        return false;
      }
    }
    return true;
  }
}