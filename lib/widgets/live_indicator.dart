import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

class LiveIndicator extends StatelessWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              duration: 1500.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.4, 1.4),
            ),
        const SizedBox(width: 6),
        Text(
          'LIVE',
          style: GoogleFonts.dmSans(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
