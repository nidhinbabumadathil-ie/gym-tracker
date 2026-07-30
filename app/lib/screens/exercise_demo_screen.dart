import 'dart:async';
import 'package:flutter/material.dart';
import '../data/exercise_demos.dart';

/// Shows an animated "how to do it" demo for a given exercise by looping
/// between its start and end position frames, with written form cues below.
class ExerciseDemoScreen extends StatefulWidget {
  final String exerciseName;
  const ExerciseDemoScreen({super.key, required this.exerciseName});

  @override
  State<ExerciseDemoScreen> createState() => _ExerciseDemoScreenState();
}

class _ExerciseDemoScreenState extends State<ExerciseDemoScreen> {
  int _frame = 0;
  Timer? _timer;
  ExerciseDemo? _demo;

  @override
  void initState() {
    super.initState();
    _demo = exerciseDemos[widget.exerciseName];

    // Flip between the frames on a loop to create the motion effect.
    if (_demo != null && _demo!.frames.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (!mounted) return;
        setState(() => _frame = (_frame + 1) % _demo!.frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = _demo;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
      ),
      body: demo == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No demo available for this exercise yet.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Animated demo ----
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: Colors.white, // frames have a white background
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Image.network(
                            demo.frames[_frame],
                            key: ValueKey<int>(_frame),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stack) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.black26, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.loop, size: 14, color: Colors.white38),
                      SizedBox(width: 6),
                      Text(
                        'Looping start → end position',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---- Instructions ----
                  const Text(
                    'How to do it',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(demo.instructions.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent, shape: BoxShape.circle),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              demo.instructions[i],
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Text(
                    'Demo: ${demo.matchedName} · Free Exercise DB (public domain)',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),
    );
  }
}
