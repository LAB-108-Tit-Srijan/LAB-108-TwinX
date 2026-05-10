import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  String _statusText = 'Tap the mic to start';
  
  // Animation controllers
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _floatAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _pulseAnimation;
  
  // Wave visualization
  final List<double> _waveHeights = List.generate(25, (_) => 0.3);
  Timer? _waveTimer;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    
    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    // Blinking animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // Start blinking for both states
    _startBlinking();
    
    // Pulse animation for mic
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final randomDelay = 2500 + Random().nextInt(2000);
    _blinkTimer = Timer(Duration(milliseconds: randomDelay), () {
      if (mounted) {
        _blink();
        _scheduleBlink();
      }
    });
  }

  Future<void> _blink() async {
    if (!mounted) return;
    await _blinkController.forward();
    if (!mounted) return;
    await _blinkController.reverse();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    _pulseController.dispose();
    _waveTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      if (_isListening) {
        _stopListening();
      } else {
        _startListening();
      }
    });
  }

  void _startListening() {
    _isListening = true;
    _statusText = 'Listening...';
    _pulseController.repeat(reverse: true);
    
    // Animate waves
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_isListening && mounted) {
        setState(() {
          for (int i = 0; i < _waveHeights.length; i++) {
            _waveHeights[i] = 0.3 + Random().nextDouble() * 0.7;
          }
        });
      }
    });
  }

  void _stopListening() {
    _isListening = false;
    _statusText = 'Tap the mic to start';
    _pulseController.stop();
    _pulseController.reset();
    _waveTimer?.cancel();
    
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E2A32),
              Color(0xFF151D23),
              Color(0xFF0D1318),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(dvpw, dvph),
              Expanded(child: _buildAvatarSection(dvpw, dvph)),
              _buildWaveVisualization(dvpw, dvph),
              SizedBox(height: dvph * 0.02),
              _buildMicButton(dvpw, dvph),
              SizedBox(height: dvph * 0.03),
              _buildBottomControls(dvpw, dvph),
              SizedBox(height: dvph * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Padding(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3740),
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(Icons.arrow_back, size: dvpw * 0.055, color: AppColors.white),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvpw * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primaryLime,
              borderRadius: BorderRadius.circular(dvpw * 0.06),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: dvpw * 0.04, color: AppColors.primaryDark),
                SizedBox(width: dvpw * 0.015),
                Text(
                  'Voice Mode',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.035,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(dvpw * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3740),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(Icons.settings, size: dvpw * 0.055, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(double dvpw, double dvph) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: dvpw * 0.65,
                    height: dvpw * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLime.withOpacity(_isListening ? 0.5 : 0.3),
                          blurRadius: _isListening ? 80 : 50,
                          spreadRadius: _isListening ? 25 : 15,
                        ),
                      ],
                    ),
                  ),
                  // Main avatar circle
                  Container(
                    width: dvpw * 0.52,
                    height: dvpw * 0.52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        colors: [
                          const Color(0xFFD4FF6B),
                          AppColors.primaryLime,
                          const Color(0xFFA8E030),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFF9AD025).withOpacity(0.6),
                        width: 4,
                      ),
                    ),
                    child: _buildCuteFace(dvpw),
                  ),
                ],
              ),
              SizedBox(height: dvph * 0.035),
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.045,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCuteFace(double dvpw) {
    return Padding(
      padding: EdgeInsets.all(dvpw * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Eyes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEye(dvpw),
              SizedBox(width: dvpw * 0.1),
              _buildEye(dvpw),
            ],
          ),
          SizedBox(height: dvpw * 0.03),
          // Blush
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBlush(dvpw),
              SizedBox(width: dvpw * 0.18),
              _buildBlush(dvpw),
            ],
          ),
          SizedBox(height: dvpw * 0.02),
          // Mouth
          _buildMouth(dvpw),
        ],
      ),
    );
  }

  Widget _buildEye(double dvpw) {
    // Base eye design (narrow oval with white highlight) - blinks in both states
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        // Calculate eye height based on blink animation
        final baseHeight = _isListening ? dvpw * 0.055 : dvpw * 0.045;
        final eyeHeight = baseHeight * _blinkAnimation.value;
        
        return Container(
          width: dvpw * 0.055,
          height: eyeHeight.clamp(dvpw * 0.005, baseHeight),
          decoration: BoxDecoration(
            color: const Color(0xFF2A3540),
            borderRadius: BorderRadius.circular(dvpw * 0.03),
          ),
          child: eyeHeight > dvpw * 0.02
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // White highlight/pupil
                  Positioned(
                    top: dvpw * 0.008,
                    right: dvpw * 0.01,
                    child: Container(
                      width: dvpw * 0.018,
                      height: dvpw * 0.018,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        );
      },
    );
  }

  Widget _buildBlush(double dvpw) {
    return Container(
      width: dvpw * 0.05,
      height: dvpw * 0.025,
      decoration: BoxDecoration(
        color: const Color(0xFFE8B4A0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(dvpw * 0.015),
      ),
    );
  }

  Widget _buildMouth(double dvpw) {
    if (_isListening) {
      // Open mouth (static, no lip sync)
      return Container(
        width: dvpw * 0.045,
        height: dvpw * 0.055,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3540),
          borderRadius: BorderRadius.circular(dvpw * 0.025),
        ),
      );
    }
    
    // Idle: Cute smile
    return SizedBox(
      width: dvpw * 0.12,
      height: dvpw * 0.06,
      child: CustomPaint(
        painter: SmilePainter(color: const Color(0xFF2A3540)),
      ),
    );
  }

  Widget _buildWaveVisualization(double dvpw, double dvph) {
    return SizedBox(
      height: dvph * 0.08,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_waveHeights.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            margin: EdgeInsets.symmetric(horizontal: dvpw * 0.005),
            width: dvpw * 0.012,
            height: _isListening ? dvph * 0.06 * _waveHeights[index] : dvph * 0.015,
            decoration: BoxDecoration(
              color: _isListening 
                ? AppColors.primaryLime 
                : AppColors.primaryLime.withOpacity(0.3),
              borderRadius: BorderRadius.circular(dvpw * 0.01),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMicButton(double dvpw, double dvph) {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: dvpw * 0.18,
              height: dvpw * 0.18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.red : AppColors.primaryLime,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.red : AppColors.primaryLime)
                        .withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic,
                size: dvpw * 0.085,
                color: _isListening ? AppColors.white : AppColors.primaryDark,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(double dvpw, double dvph) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(Icons.keyboard, 'Type', dvpw, () => Navigator.pop(context)),
          _buildControlButton(Icons.volume_up, 'Speaker', dvpw, () {}),
          _buildControlButton(Icons.history, 'History', dvpw, () {}),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, double dvpw, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(dvpw * 0.04),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3740),
              borderRadius: BorderRadius.circular(dvpw * 0.035),
            ),
            child: Icon(icon, size: dvpw * 0.055, color: AppColors.white),
          ),
          SizedBox(height: dvpw * 0.02),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.03,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for cute smile
class SmilePainter extends CustomPainter {
  final Color color;
  
  SmilePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.1,
      size.width * 0.85,
      size.height * 0.35,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
