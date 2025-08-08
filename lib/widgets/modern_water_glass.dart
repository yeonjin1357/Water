import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';

class ModernWaterGlass extends StatefulWidget {
  final double waterLevel;
  final int currentAmount;
  final int goalAmount;

  const ModernWaterGlass({
    super.key,
    required this.waterLevel,
    required this.currentAmount,
    required this.goalAmount,
  });

  @override
  State<ModernWaterGlass> createState() => _ModernWaterGlassState();
}

class _ModernWaterGlassState extends State<ModernWaterGlass>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late AnimationController _bubbleController;
  late Animation<double> _fillAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wave animation - smoother infinite loop
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1, // Keep at 1 for proper cycle
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
    
    // Fill animation
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.waterLevel,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Bubble animation
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _bubbleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.linear,
    ));
    
    _fillController.forward();
  }

  @override
  void didUpdateWidget(ModernWaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waterLevel != widget.waterLevel) {
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: widget.waterLevel,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeInOutCubic,
      ));
      _fillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 240,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _waveController,
              _fillController,
              _bubbleController,
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: ModernGlassPainter(
                  waterLevel: _fillAnimation.value,
                  waveAnimation: _waveAnimation.value,
                  bubbleAnimation: _bubbleAnimation.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.currentAmount}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  ' / ${widget.goalAmount}ml',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.waterLevel.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF64B5F6),
                        Color(0xFF42A5F5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(widget.waterLevel * 100).toInt()}% ${AppLocalizations.get('ofDailyGoal')}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ModernGlassPainter extends CustomPainter {
  final double waterLevel;
  final double waveAnimation;
  final double bubbleAnimation;

  ModernGlassPainter({
    required this.waterLevel,
    required this.waveAnimation,
    required this.bubbleAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glassHeight = size.height * 0.85;
    final glassWidth = size.width * 0.7;
    
    // Modern glass shape (slightly tapered)
    final topWidth = glassWidth;
    final bottomWidth = glassWidth * 0.85;
    final glassTop = center.dy - glassHeight / 2;
    final glassBottom = center.dy + glassHeight / 2;
    
    // Glass path
    final glassPath = Path();
    final radius = 20.0;
    
    // Top left
    glassPath.moveTo(center.dx - topWidth / 2 + radius, glassTop);
    glassPath.quadraticBezierTo(
      center.dx - topWidth / 2, glassTop,
      center.dx - topWidth / 2, glassTop + radius,
    );
    
    // Left side
    glassPath.lineTo(center.dx - bottomWidth / 2, glassBottom - radius);
    
    // Bottom left
    glassPath.quadraticBezierTo(
      center.dx - bottomWidth / 2, glassBottom,
      center.dx - bottomWidth / 2 + radius, glassBottom,
    );
    
    // Bottom
    glassPath.lineTo(center.dx + bottomWidth / 2 - radius, glassBottom);
    
    // Bottom right
    glassPath.quadraticBezierTo(
      center.dx + bottomWidth / 2, glassBottom,
      center.dx + bottomWidth / 2, glassBottom - radius,
    );
    
    // Right side
    glassPath.lineTo(center.dx + topWidth / 2, glassTop + radius);
    
    // Top right
    glassPath.quadraticBezierTo(
      center.dx + topWidth / 2, glassTop,
      center.dx + topWidth / 2 - radius, glassTop,
    );
    
    // Top
    glassPath.close();
    
    // Draw glass background with gradient
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.95),
        Colors.white.withValues(alpha: 0.85),
      ],
    );
    
    final glassPaint = Paint()
      ..shader = glassGradient.createShader(
        Rect.fromLTWH(center.dx - topWidth / 2, glassTop, topWidth, glassHeight),
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(glassPath, glassPaint);
    
    // Draw water if level > 0
    if (waterLevel > 0.01) {
      canvas.save();
      canvas.clipPath(glassPath);
      
      final waterHeight = glassHeight * waterLevel;
      final waterTop = glassBottom - waterHeight;
      
      // Calculate water width at current height - fixed calculation
      final waterProgress = waterLevel;
      final waterWidth = bottomWidth + (topWidth - bottomWidth) * waterProgress;
      
      // Create water gradient
      final waterGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF42A5F5).withValues(alpha: 0.8),
          const Color(0xFF1E88E5).withValues(alpha: 0.9),
        ],
      );
      
      final waterPaint = Paint()
        ..shader = waterGradient.createShader(
          Rect.fromLTWH(center.dx - waterWidth / 2, waterTop,
                        waterWidth, waterHeight),
        );
      
      // Draw water with smooth waves
      final waterPath = Path();
      
      // Create smooth wave effect with seamless loop
      for (int i = 0; i <= 100; i++) {
        final x = i / 100.0;
        final waveX = center.dx - waterWidth / 2 + (waterWidth * x);
        
        // Seamless wave calculation - all waves complete full cycles
        final wave1 = math.sin((x * math.pi * 2) + (waveAnimation * math.pi * 2)) * 4;
        final wave2 = math.sin((x * math.pi * 4) - (waveAnimation * math.pi * 2)) * 2;  // Opposite direction for natural interference
        final wave3 = math.cos((x * math.pi * 2) + (waveAnimation * math.pi * 4)) * 1;
        
        final waveY = waterTop + wave1 + wave2 + wave3;
        
        if (i == 0) {
          waterPath.moveTo(waveX, waveY);
        } else {
          waterPath.lineTo(waveX, waveY);
        }
      }
      
      // Follow glass contours properly - right side
      final rightX = center.dx + waterWidth / 2;
      waterPath.lineTo(rightX, waterTop);
      
      // Calculate positions for glass slope
      for (double y = waterTop; y <= glassBottom; y += 5) {
        final progress = (glassBottom - y) / glassHeight;
        final xPos = center.dx + bottomWidth / 2 + (topWidth - bottomWidth) / 2 * progress;
        waterPath.lineTo(xPos, y);
      }
      
      // Bottom
      waterPath.lineTo(center.dx + bottomWidth / 2, glassBottom);
      waterPath.lineTo(center.dx - bottomWidth / 2, glassBottom);
      
      // Follow glass contours - left side  
      for (double y = glassBottom; y >= waterTop; y -= 5) {
        final progress = (glassBottom - y) / glassHeight;
        final xPos = center.dx - bottomWidth / 2 - (topWidth - bottomWidth) / 2 * progress;
        waterPath.lineTo(xPos, y);
      }
      
      waterPath.close();
      
      canvas.drawPath(waterPath, waterPaint);
      
      // Draw bubbles
      if (waterLevel > 0.1) {
        _drawBubbles(canvas, center, waterTop, waterHeight, waterWidth);
      }
      
      // Water surface highlight
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTWH(center.dx - waterWidth / 2, waterTop,
                        waterWidth, 20),
        );
      
      final highlightPath = Path();
      highlightPath.moveTo(center.dx - waterWidth / 2, waterTop);
      
      for (int i = 0; i <= 100; i++) {
        final x = i / 100.0;
        final waveX = center.dx - waterWidth / 2 + (waterWidth * x);
        // Match the main water wave for consistency
        final wave1 = math.sin((x * math.pi * 2) + (waveAnimation * math.pi * 2)) * 4;
        final wave2 = math.sin((x * math.pi * 4) - (waveAnimation * math.pi * 2)) * 2;
        final wave3 = math.cos((x * math.pi * 2) + (waveAnimation * math.pi * 4)) * 1;
        final waveY = waterTop + wave1 + wave2 + wave3;
        highlightPath.lineTo(waveX, waveY);
      }
      
      highlightPath.lineTo(center.dx + waterWidth / 2, waterTop + 20);
      highlightPath.lineTo(center.dx - waterWidth / 2, waterTop + 20);
      highlightPath.close();
      
      canvas.drawPath(highlightPath, highlightPaint);
      canvas.restore();
    }
    
    // Draw glass outline
    final glassBorderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(glassPath, glassBorderPaint);
    
    // Add glass reflection that follows glass contour
    final reflectionPath = Path();
    
    // Start from top left, slightly inset
    final reflectionTopX = center.dx - topWidth / 2 + 25;
    final reflectionBottomX = center.dx - bottomWidth / 2 + 20;
    
    // Create a curved reflection that follows the glass shape
    reflectionPath.moveTo(reflectionTopX, glassTop + 15);
    
    // Add multiple points to create smooth curve following glass contour
    for (double progress = 0; progress <= 1; progress += 0.1) {
      final y = glassTop + 15 + (glassHeight - 55) * progress;
      // Interpolate x position based on glass slope
      final x = reflectionTopX + (reflectionBottomX - reflectionTopX) * progress;
      
      if (progress == 0) {
        reflectionPath.moveTo(x, y);
      } else {
        reflectionPath.lineTo(x, y);
      }
    }
    
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(reflectionTopX - 10, glassTop, 50, glassHeight),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(reflectionPath, reflectionPaint);
  }
  
  void _drawBubbles(Canvas canvas, Offset center, double waterTop,
                     double waterHeight, double waterWidth) {
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final bubbleCount = 5;
    for (int i = 0; i < bubbleCount; i++) {
      final progress = (bubbleAnimation + i / bubbleCount) % 1.0;
      final bubbleY = waterTop + waterHeight - (waterHeight * progress * 0.8);
      final bubbleX = center.dx + math.sin(i * 1.5) * (waterWidth * 0.3);
      final bubbleSize = 2.0 + math.sin(i) * 1.5;
      
      final opacity = (1.0 - progress) * 0.3;
      bubblePaint.color = Colors.white.withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleSize,
        bubblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(ModernGlassPainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
           oldDelegate.waveAnimation != waveAnimation ||
           oldDelegate.bubbleAnimation != bubbleAnimation;
  }
}