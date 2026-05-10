import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/quiz_service.dart';

class QuizModal extends StatefulWidget {
  final String lectureId;
  final List<dynamic> questions;

  const QuizModal({
    super.key,
    required this.lectureId,
    required this.questions,
  });

  @override
  State<QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<QuizModal> {
  int _currentQuestion = 0;
  int? _selectedOption;
  final List<int> _answers = [];
  bool _submitted = false;
  Map<String, dynamic>? _result;
  bool _submitting = false;

  List<dynamic> get _questions => widget.questions;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await QuizService.submitAttempt(widget.lectureId, _answers);
      if (mounted) {
        setState(() {
          _result = res;
          _submitted = true;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Container(
      height: dvph * 0.85,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(dvpw * 0.06)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: EdgeInsets.only(top: dvph * 0.015),
            child: Container(
              width: dvpw * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: _submitted ? _buildResult(dvpw, dvph) : _buildQuiz(dvpw, dvph),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(double dvpw, double dvph) {
    final score = _result?['score'] ?? 0;
    final total = _result?['total'] ?? _questions.length;
    final passed = _result?['passed'] == true;
    final credits = _result?['credits_earned'] ?? 0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(dvpw * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              passed ? '🎉' : '📚',
              style: TextStyle(fontSize: dvpw * 0.18),
            ),
            SizedBox(height: dvph * 0.025),
            Text(
              passed ? 'Great Job!' : 'Keep Practicing!',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.065,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: dvph * 0.01),
            Text(
              'Score: $score out of $total',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.045,
                color: AppColors.gray,
              ),
            ),
            if (credits > 0) ...[
              SizedBox(height: dvph * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: dvpw * 0.05, vertical: dvpw * 0.025),
                decoration: BoxDecoration(
                  color: AppColors.primaryLime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(dvpw * 0.035),
                ),
                child: Text(
                  '+$credits XP Earned!',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.048,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
            SizedBox(height: dvph * 0.05),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(dvpw * 0.04)),
                ),
                child: Text(
                  'Continue Learning',
                  style: GoogleFonts.lato(
                      fontSize: dvpw * 0.042, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(double dvpw, double dvph) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available',
          style: GoogleFonts.lato(fontSize: dvpw * 0.042, color: AppColors.gray),
        ),
      );
    }

    final q = _questions[_currentQuestion] as Map<String, dynamic>;
    final questionText =
        q['question']?.toString() ?? q['text']?.toString() ?? 'Question';
    final options = (q['options'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        // Progress header
        Padding(
          padding: EdgeInsets.fromLTRB(dvpw * 0.05, dvph * 0.015, dvpw * 0.05, 0),
          child: Row(
            children: [
              Text(
                'Quiz',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.05,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentQuestion + 1} / ${_questions.length}',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.038,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: dvpw * 0.05, vertical: dvph * 0.01),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(dvpw * 0.01),
            child: LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              backgroundColor: AppColors.grayLight,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
              minHeight: dvph * 0.01,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(dvpw * 0.05, dvph * 0.02, dvpw * 0.05, dvph * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.045,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: dvph * 0.025),
                ...options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value.toString();
                  final isSelected = _selectedOption == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOption = idx),
                    child: Container(
                      margin: EdgeInsets.only(bottom: dvph * 0.012),
                      padding: EdgeInsets.all(dvpw * 0.04),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLime.withOpacity(0.15)
                            : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(dvpw * 0.035),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLime : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: dvpw * 0.07,
                            height: dvpw * 0.07,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primaryLime
                                  : AppColors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryLime
                                    : AppColors.grayLight,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    size: dvpw * 0.04,
                                    color: AppColors.primaryDark)
                                : null,
                          ),
                          SizedBox(width: dvpw * 0.03),
                          Expanded(
                            child: Text(
                              opt,
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.038,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: dvph * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedOption == null || _submitting
                        ? null
                        : () {
                            _answers.add(_selectedOption!);
                            if (_currentQuestion < _questions.length - 1) {
                              setState(() {
                                _currentQuestion++;
                                _selectedOption = null;
                              });
                            } else {
                              _submit();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grayLight,
                      padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(dvpw * 0.04)),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: dvpw * 0.05,
                            height: dvpw * 0.05,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            _currentQuestion < _questions.length - 1
                                ? 'Next'
                                : 'Submit Quiz',
                            style: GoogleFonts.lato(
                                fontSize: dvpw * 0.042,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
