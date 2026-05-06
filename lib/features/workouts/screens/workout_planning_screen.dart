import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutPlanningScreen extends StatelessWidget {
  const WorkoutPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Workouts',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.fitness_center_rounded, 
                size: 64, 
                color: Colors.blueAccent
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Training Mode Soon',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'We are building the ultimate workout planner for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
