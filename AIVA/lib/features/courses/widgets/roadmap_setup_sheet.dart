import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../roadmap/screens/roadmap_screen.dart';

class RoadmapSetupSheet extends StatefulWidget {
  final String enrollmentId;
  final String courseTitle;

  const RoadmapSetupSheet({
    super.key,
    required this.enrollmentId,
    required this.courseTitle,
  });

  @override
  State<RoadmapSetupSheet> createState() => _RoadmapSetupSheetState();
}

class _RoadmapSetupSheetState extends State<RoadmapSetupSheet> {
  final _goalController = TextEditingController();
  double _dailyHours = 1.0;
  double _targetDays = 30;
  bool _generating = false;
  String? _error;

  static const _hourOptions = [0.5, 1.0, 1.5, 2.0, 3.0];

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_goalController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your goal');
      return;
    }
    setState(() { _generating = true; _error = null; });

    try {
      final result = await ApiService.post('/api/roadmap/generate', {
        'enrollment_id': widget.enrollmentId,
        'goal': _goalController.text.trim(),
        'daily_hours': _dailyHours.round(),
        'target_days': _targetDays.round(),
      });

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoadmapScreen(
              enrollmentId: widget.enrollmentId,
              generatedPlan: result['plan'] as Map<String, dynamic>?,
            ),
          ),
        );
      } else {
        setState(() {
          _error = result['error']?.toString() ?? 'Failed to generate roadmap';
          _generating = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Container(
      height: dvph * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: dvph * 0.015),
            width: dvpw * 0.12,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(dvpw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalize Your Learning',
                    style: GoogleFonts.lato(fontSize: dvpw * 0.055, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: dvph * 0.008),
                  Text(
                    'AIVA will create a custom plan for: ${widget.courseTitle}',
                    style: GoogleFonts.lato(fontSize: dvpw * 0.035, color: Colors.white60),
                  ),
                  SizedBox(height: dvph * 0.035),

                  // Goal field
                  Text("What's your goal?", style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(height: dvph * 0.012),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: TextField(
                      controller: _goalController,
                      style: GoogleFonts.lato(color: Colors.white, fontSize: dvpw * 0.038),
                      decoration: InputDecoration(
                        hintText: 'e.g. Get a job in React development',
                        hintStyle: GoogleFonts.lato(color: Colors.white38, fontSize: dvpw * 0.038),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(dvpw * 0.04),
                      ),
                      maxLines: 2,
                    ),
                  ),

                  SizedBox(height: dvph * 0.03),

                  // Hours per day selector
                  Text('Hours per day?', style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(height: dvph * 0.012),
                  Row(
                    children: _hourOptions.map((h) {
                      final isSelected = _dailyHours == h;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _dailyHours = h),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.symmetric(horizontal: dvpw * 0.01),
                            padding: EdgeInsets.symmetric(vertical: dvph * 0.012),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLime : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(dvpw * 0.025),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLime : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              h == h.toInt() ? '${h.toInt()}h' : '${h}h',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.032,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primaryDark : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: dvph * 0.03),

                  // Days slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Complete in how many days?', style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('${_targetDays.round()} days', style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w700, color: AppColors.primaryLime)),
                    ],
                  ),
                  SizedBox(height: dvph * 0.01),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primaryLime,
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: AppColors.primaryLime,
                      overlayColor: AppColors.primaryLime.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _targetDays,
                      min: 7,
                      max: 90,
                      divisions: 83,
                      onChanged: (v) => setState(() => _targetDays = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('7 days', style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: Colors.white38)),
                      Text('90 days', style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: Colors.white38)),
                    ],
                  ),

                  if (_error != null) ...[
                    SizedBox(height: dvph * 0.02),
                    Container(
                      padding: EdgeInsets.all(dvpw * 0.04),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(dvpw * 0.025),
                      ),
                      child: Text(_error!, style: GoogleFonts.lato(color: AppColors.red, fontSize: dvpw * 0.035)),
                    ),
                  ],

                  SizedBox(height: dvph * 0.035),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generating ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLime,
                        foregroundColor: AppColors.primaryDark,
                        disabledBackgroundColor: AppColors.primaryLime.withOpacity(0.5),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.035)),
                      ),
                      child: _generating
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: dvpw * 0.05, height: dvpw * 0.05, child: const CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2.5)),
                              SizedBox(width: dvpw * 0.03),
                              Text('Generating your plan...', style: GoogleFonts.lato(fontSize: dvpw * 0.04, fontWeight: FontWeight.w700)),
                            ])
                          : Text('Generate My Roadmap', style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
