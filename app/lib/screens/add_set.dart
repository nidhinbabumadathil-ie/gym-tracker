import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../services/api_service.dart';
import '../data/pb_store.dart';

class AddSetScreen extends StatefulWidget {
  final int sessionId;

  const AddSetScreen({super.key, required this.sessionId});

  @override
  State<AddSetScreen> createState() => _AddSetScreenState();
}

class _AddSetScreenState extends State<AddSetScreen> {
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();

  int setNumber = 1;
  bool resting = false;
  static const int restDuration = 90;

  // Wall-clock rest timer: survives screen lock.
  DateTime? restEndsAt;
  Timer? ticker;
  bool submitting = false;
  bool _alarmFired = false; // guard so the alarm only rings once per rest

  late final ConfettiController _confetti;
  String exerciseName = "Add Set";
  double? currentBest;
  String? pbMessage;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    exerciseName = args?['workoutName'] ?? "Add Set";
    PbStore.best(exerciseName).then((b) {
      if (mounted) setState(() => currentBest = b);
    });
  }

  int get remaining {
    if (restEndsAt == null) return 0;
    final secs = restEndsAt!.difference(DateTime.now()).inSeconds;
    return secs < 0 ? 0 : secs;
  }

  void startRestTimer() {
    restEndsAt = DateTime.now().add(const Duration(seconds: restDuration));
    _alarmFired = false;
    setState(() => resting = true);

    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining <= 0) {
        t.cancel();
        _fireRestAlarm();
        setState(() => resting = false);
      } else {
        setState(() {});
      }
    });
  }

  // Sound + vibration when rest ends. Uses only built-in Flutter APIs, so
  // there are no extra packages or asset files to add.
  Future<void> _fireRestAlarm() async {
    if (_alarmFired) return;
    _alarmFired = true;

    // Audible cue.
    SystemSound.play(SystemSoundType.alert);

    // Buzz a few times so it's felt even if the phone is on a bench.
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rest over — next set!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void skipRest() {
    ticker?.cancel();
    setState(() {
      resting = false;
      restEndsAt = null;
    });
  }

  Future<void> submitSet() async {
    final weight = double.tryParse(weightCtrl.text.trim());
    final reps = int.tryParse(repsCtrl.text.trim());

    if (weight == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid weight and reps")),
      );
      return;
    }

    setState(() {
      submitting = true;
      pbMessage = null;
    });

    try {
      await ApiService.addSet(
        sessionId: widget.sessionId,
        setNumber: setNumber,
        weight: weight,
        reps: reps,
        restSeconds: restDuration,
      );

      final isPb = await PbStore.record(exerciseName, weight);
      if (isPb && mounted) {
        _confetti.play();
        setState(() {
          currentBest = weight;
          pbMessage = "New personal best: ${_fmt(weight)} kg!";
        });
      }

      setNumber++;
      weightCtrl.clear();
      repsCtrl.clear();
      startRestTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save set: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void dispose() {
    ticker?.cancel();
    _confetti.dispose();
    weightCtrl.dispose();
    repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (remaining ~/ 60).toString().padLeft(2, '0');
    final secs = (remaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (currentBest != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Best so far: ${_fmt(currentBest!)} kg",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: pbMessage == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: const ValueKey('pb'),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1414),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Text(
                            pbMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(labelText: "Weight (kg)"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: "Reps"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (resting || submitting) ? null : submitSet,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Submit Set"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, exerciseName);
                  },
                  child: const Text("Done with this exercise"),
                ),
                const SizedBox(height: 30),
                if (resting)
                  Column(
                    children: [
                      const Text("Rest",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        "$mins:$secs",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: skipRest,
                        child: const Text("Skip Rest"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 22,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.redAccent,
                Colors.white,
                Colors.amber,
                Colors.orangeAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
