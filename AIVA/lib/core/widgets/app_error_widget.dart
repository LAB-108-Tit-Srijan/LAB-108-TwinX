import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dvpw * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(dvpw * 0.04),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: dvpw * 0.1, color: AppColors.red),
            ),
            SizedBox(height: dvpw * 0.04),
            Text(
              'Something went wrong',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: dvpw * 0.02),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: dvpw * 0.035, color: AppColors.gray),
            ),
            if (onRetry != null) ...[
              SizedBox(height: dvpw * 0.05),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLime,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: dvpw * 0.06, vertical: dvpw * 0.03),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.03)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Retry', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
