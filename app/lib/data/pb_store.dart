import 'package:shared_preferences/shared_preferences.dart';

/// Tracks each exercise's best (heaviest) weight on the device.
///
/// This keeps personal bests working with no backend change. Trade-off: bests
/// are per-device and start from the first set logged after this feature was
/// added (they don't mine older history stored on the server).
class PbStore {
  static String _key(String exercise) =>
      'pb_${exercise.toLowerCase().trim()}';

  /// The stored best weight for an exercise, or null if none recorded yet.
  static Future<double?> best(String exercise) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key(exercise));
  }

  /// Records [weight] for [exercise] if it's a new best.
  ///
  /// Returns true only when it *beats* a previous best (worth celebrating).
  /// The first set for an exercise silently becomes the baseline, so you don't
  /// get confetti simply for trying an exercise for the first time.
  static Future<bool> record(String exercise, double weight) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_key(exercise));

    if (current == null) {
      await prefs.setDouble(_key(exercise), weight);
      return false; // baseline set, not a celebration
    }
    if (weight > current) {
      await prefs.setDouble(_key(exercise), weight);
      return true; // new personal best!
    }
    return false;
  }
}
