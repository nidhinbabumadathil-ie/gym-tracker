import 'package:flutter/material.dart';
import '../data/workout_plan.dart';
import 'exercise_demo_screen.dart';

class _ExerciseEntry {
  final String name;
  final String muscle;
  const _ExerciseEntry(this.name, this.muscle);
}

class ExerciseSearchScreen extends StatefulWidget {
  const ExerciseSearchScreen({super.key});

  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _muscle = 'All';

  late final List<_ExerciseEntry> _index = _buildIndex();
  late final List<String> _muscles = _buildMuscles();

  // Flatten the plan into a unique, sorted list of exercises + their muscle.
  List<_ExerciseEntry> _buildIndex() {
    final seen = <String>{};
    final list = <_ExerciseEntry>[];
    for (final day in workoutPlan.values) {
      day.forEach((muscle, exercises) {
        for (final e in exercises) {
          if (seen.add(e)) list.add(_ExerciseEntry(e, muscle));
        }
      });
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<String> _buildMuscles() {
    final set = <String>{for (final e in _index) e.muscle};
    final sorted = set.toList()..sort();
    return ['All', ...sorted];
  }

  List<_ExerciseEntry> get _filtered {
    final q = _query.toLowerCase().trim();
    return _index.where((e) {
      final matchMuscle = _muscle == 'All' || e.muscle == _muscle;
      final matchQuery = q.isEmpty || e.name.toLowerCase().contains(q);
      return matchMuscle && matchQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Muscle filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = _muscles[i];
                final selected = m == _muscle;
                return ChoiceChip(
                  label: Text(m),
                  selected: selected,
                  onSelected: (_) => setState(() => _muscle = m),
                  showCheckmark: false,
                  selectedColor: Colors.redAccent,
                  backgroundColor: const Color(0xFF1A1A1A),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? Colors.redAccent : Colors.white12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('No exercises found',
                        style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final e = results[i];
                      return Card(
                        color: const Color(0xFF161616),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(e.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(e.muscle,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 12)),
                          trailing: const Icon(Icons.play_circle_outline,
                              color: Colors.white38),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseDemoScreen(exerciseName: e.name),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
