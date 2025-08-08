import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterGlassWidget extends StatefulWidget {
  final double waterLevel;
  final int currentAmount;
  final int goalAmount;
  
  const WaterGlassWidget({
    super.key,
    required this.waterLevel,
    required this.currentAmount,
    required this.goalAmount,
  });

  @override
  State<WaterGlassWidget> createState() => _WaterGlassWidgetState();
}

class _WaterGlassWidgetState extends State<WaterGlassWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _currentWaterLevel = 0;
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.waterLevel,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));
    
    _currentWaterLevel = widget.waterLevel;
    _fillController.forward();
  }
  
  @override
  void didUpdateWidget(WaterGlassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waterLevel != widget.waterLevel) {
      _fillAnimation = Tween<double>(
        begin: _currentWaterLevel,
        end: widget.waterLevel,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      _fillController
        ..reset()
        ..forward();
      _currentWaterLevel = widget.waterLevel;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 300,
          child: AnimatedBuilder(
            animation: Listenable.merge([_waveController, _fillController]),
            builder: (context, child) {
              return CustomPaint(
                painter: WaterGlassPainter(
                  waterLevel: _fillAnimation.value,
                  waveAnimation: _waveController.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${widget.currentAmount}ml',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Hydration • ${(widget.waterLevel * 100).toInt()}% of your goal',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class WaterGlassPainter extends CustomPainter {
  final double waterLevel;
  final double waveAnimation;
  
  WaterGlassPainter({
    required this.waterLevel,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glassHeight = size.height * 0.75;
    final topRadius = size.width * 0.35;
    final bottomRadius = size.width * 0.25;
    final glassTop = center.dy - glassHeight / 2;
    final glassBottom = center.dy + glassHeight / 2;
    
    // Draw glass shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    final shadowPath = Path();
    shadowPath.moveTo(center.dx - topRadius, glassTop + 5);
    shadowPath.lineTo(center.dx - bottomRadius, glassBottom + 5);
    shadowPath.lineTo(center.dx + bottomRadius, glassBottom + 5);
    shadowPath.lineTo(center.dx + topRadius, glassTop + 5);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw glass background with gradient
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.grey[100]!.withOpacity(0.05),
      ],
    );
    
    final glassBackPaint = Paint()
      ..shader = glassGradient.createShader(
        Rect.fromLTWH(center.dx - topRadius, glassTop, 
                      topRadius * 2, glassHeight),
      )
      ..style = PaintingStyle.fill;
    
    final glassPath = Path();
    glassPath.moveTo(center.dx - topRadius, glassTop);
    glassPath.lineTo(center.dx - bottomRadius, glassBottom);
    glassPath.lineTo(center.dx + bottomRadius, glassBottom);
    glassPath.lineTo(center.dx + topRadius, glassTop);
    glassPath.close();
    
    canvas.drawPath(glassPath, glassBackPaint);
    
    // Draw water if present
    if (waterLevel > 0) {
      canvas.save();
      canvas.clipPath(glassPath);
      
      final waterHeight = glassHeight * waterLevel;
      final waterTop = glassBottom - waterHeight;
      
      // Calculate radius at water level
      final waterProgress = waterLevel;
      final waterRadius = bottomRadius + 
          (topRadius - bottomRadius) * waterProgress;
      
      // Draw water with multiple wave layers for natural effect
      final waterGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF64B5F6).withValues(alpha: 0.5),  // Light blue
          const Color(0xFF42A5F5).withValues(alpha: 0.7),  // Deeper blue
        ],
      );
      
      final waterPaint = Paint()
        ..shader = waterGradient.createShader(
          Rect.fromLTWH(center.dx - waterRadius, waterTop,
                        waterRadius * 2, waterHeight),
        );
      
      // Draw water with waves
      final waterPath = Path();
      
      // Create wave surface
      waterPath.moveTo(center.dx - waterRadius, waterTop);
      
      for (int i = 0; i <= 100; i++) {
        final x = i / 100.0;
        final waveX = center.dx - waterRadius + (waterRadius * 2 * x);
        
        // Multiple wave layers for more natural effect
        final wave1 = math.sin((x * math.pi * 2) + (waveAnimation * math.pi * 2)) * 6;
        final wave2 = math.sin((x * math.pi * 3) + (waveAnimation * math.pi * 3)) * 4;
        final wave3 = math.cos((x * math.pi * 4) + (waveAnimation * math.pi * 1.5)) * 2;
        final wave4 = math.sin((x * math.pi * 5) + (waveAnimation * math.pi * 4)) * 1.5;
        
        final waveY = waterTop + wave1 + wave2 + wave3 + wave4;
        waterPath.lineTo(waveX, waveY);
      }
      
      // Complete water shape following glass contours
      waterPath.lineTo(center.dx + waterRadius, waterTop);
      waterPath.lineTo(center.dx + bottomRadius, glassBottom);
      waterPath.lineTo(center.dx - bottomRadius, glassBottom);
      waterPath.close();
      
      canvas.drawPath(waterPath, waterPaint);
      
      // Add water surface highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      final highlightPath = Path();
      highlightPath.moveTo(center.dx - waterRadius * 0.8, waterTop + 5);
      for (int i = 0; i <= 100; i++) {
        final x = i / 100.0;
        final waveX = center.dx - waterRadius * 0.8 + (waterRadius * 1.6 * x);
        final waveY = waterTop + 5 + 
            math.sin((x * math.pi * 2) + (waveAnimation * math.pi * 2)) * 3 +
            math.cos((x * math.pi * 3) + (waveAnimation * math.pi * 1.5)) * 2;
        highlightPath.lineTo(waveX, waveY);
      }
      highlightPath.lineTo(center.dx + waterRadius * 0.8, waterTop + 15);
      highlightPath.lineTo(center.dx - waterRadius * 0.8, waterTop + 15);
      highlightPath.close();
      
      canvas.drawPath(highlightPath, highlightPaint);
      canvas.restore();
    }
    
    // Draw glass outline
    final glassPaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(glassPath, glassPaint);
    
    // Add glass highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - topRadius * 0.9, glassTop + 10);
    highlightPath.lineTo(center.dx - bottomRadius * 0.85, glassBottom - 20);
    
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(WaterGlassPainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
           oldDelegate.waveAnimation != waveAnimation;
  }
}