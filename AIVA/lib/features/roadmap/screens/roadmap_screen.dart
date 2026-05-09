import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../progress/models/progress_data.dart';

class RoadmapScreen extends StatefulWidget {
  final String? initialSubjectId;
  
  const RoadmapScreen({super.key, this.initialSubjectId});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Subject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubjectId != null) {
      _selectedSubject = sampleSubjects.firstWhere(
        (s) => s.id == widget.initialSubjectId,
        orElse: () => sampleSubjects.first,
      );
    } else if (sampleSubjects.isNotEmpty) {
      _selectedSubject = sampleSubjects.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(dvpw, dvph),
            _buildSubjectSelector(dvpw, dvph),
            Expanded(
              child: _selectedSubject != null && subjectRoadmaps.containsKey(_selectedSubject!.id)
                  ? _buildRoadmapContent(dvpw, dvph)
                  : _buildEmptyState(dvpw, dvph),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grayLight.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.025),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: dvpw * 0.06,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(
              Icons.route_rounded,
              size: dvpw * 0.06,
              color: AppColors.teal,
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Roadmaps',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.055,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Your path to mastery',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: dvph * 0.015),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
        child: Row(
          children: sampleSubjects.map((subject) {
            final isSelected = _selectedSubject?.id == subject.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedSubject = subject),
              child: Container(
                margin: EdgeInsets.only(right: dvpw * 0.03),
                padding: EdgeInsets.symmetric(
                  horizontal: dvpw * 0.04,
                  vertical: dvpw * 0.03,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(dvpw * 0.03),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDark : AppColors.grayLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(subject.icon, style: TextStyle(fontSize: dvpw * 0.045)),
                    SizedBox(width: dvpw * 0.02),
                    Text(
                      subject.name,
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.035,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.white : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoadmapContent(double dvpw, double dvph) {
    final steps = subjectRoadmaps[_selectedSubject!.id]!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Overview Card
          _buildProgressOverview(steps, dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          
          // Roadmap Steps
          Text(
            'Learning Path',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            return _buildRoadmapStep(step, isLast, dvpw, dvph);
          }),
          
          SizedBox(height: dvph * 0.05),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(List<RoadmapStep> steps, double dvpw, double dvph) {
    final completed = steps.where((s) => s.isCompleted).length;
    final total = steps.length;
    final progress = total > 0 ? completed / total : 0.0;
    
    return Container(
      padding: EdgeInsets.all(dvpw * 0.05),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(dvpw * 0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedSubject?.name ?? ''} Progress',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.045,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: dvph * 0.005),
                    Text(
                      '$completed of $total milestones completed',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.032,
                        color: AppColors.grayLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: dvpw * 0.18,
                height: dvpw * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withOpacity(0.1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: dvpw * 0.15,
                      height: dvpw * 0.15,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: AppColors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.04,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: dvph * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(dvpw * 0.015),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
              minHeight: dvph * 0.012,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep(RoadmapStep step, bool isLast, double dvpw, double dvph) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: dvpw * 0.12,
              height: dvpw * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? AppColors.green
                    : step.isCurrent
                        ? AppColors.primaryLime
                        : AppColors.grayLight,
                border: step.isCurrent
                    ? Border.all(color: AppColors.primaryDark, width: 3)
                    : null,
                boxShadow: step.isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primaryLime.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: step.isCompleted
                    ? Icon(Icons.check, color: AppColors.white, size: dvpw * 0.06)
                    : Text(
                        '${step.order}',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.045,
                          fontWeight: FontWeight.w800,
                          color: step.isCurrent ? AppColors.primaryDark : AppColors.gray,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: dvph * 0.1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: step.isCompleted
                        ? [AppColors.green, AppColors.green]
                        : [AppColors.grayLight, AppColors.grayLight],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: dvpw * 0.04),
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: dvph * 0.02),
            padding: EdgeInsets.all(dvpw * 0.04),
            decoration: BoxDecoration(
              color: step.isCurrent
                  ? AppColors.primaryLime.withOpacity(0.15)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(dvpw * 0.04),
              border: step.isCurrent
                  ? Border.all(color: AppColors.primaryLime, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    if (step.isCurrent)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: dvpw * 0.025,
                          vertical: dvpw * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLime,
                          borderRadius: BorderRadius.circular(dvpw * 0.02),
                        ),
                        child: Text(
                          'In Progress',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.028,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    if (step.isCompleted)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: dvpw * 0.025,
                          vertical: dvpw * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(dvpw * 0.02),
                        ),
                        child: Text(
                          'Completed',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.028,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: dvph * 0.008),
                Text(
                  step.description,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.035,
                    color: AppColors.gray,
                    height: 1.4,
                  ),
                ),
                if (step.isCurrent) ...[
                  SizedBox(height: dvph * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: dvph * 0.012),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(dvpw * 0.025),
                            ),
                          ),
                          child: Text(
                            'Continue Learning',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.035,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double dvpw, double dvph) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_rounded,
            size: dvpw * 0.2,
            color: AppColors.grayLight,
          ),
          SizedBox(height: dvph * 0.02),
          Text(
            'Select a subject',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.gray,
            ),
          ),
          Text(
            'View your learning roadmap',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.035,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

