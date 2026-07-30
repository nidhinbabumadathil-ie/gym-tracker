// Single source of truth for the training split.
//
// Six distinct training days (no repeating 3-day cycle). Exercise names here
// must match the keys in `exercise_demos.dart` so the "How to do it" demo
// opens for every exercise.

/// Short name for each training day, e.g. 1 -> "Legs & Abs".
const Map<int, String> splitNames = {
  1: "Legs & Abs",
  2: "Back & Biceps",
  3: "Chest & Shoulders",
  4: "Triceps & Biceps",
  5: "Back & Legs",
  6: "Shoulders, Chest & Triceps",
};

const List<String> _legs = [
  "Barbell Squats",
  "Leg Press",
  "Leg Extension",
  "Hamstring Curl",
  "Dumbbell Squats",
  "Calf Raises",
];

const List<String> _abs = [
  "Crunches",
  "Russian Twist",
  "Leg Raises",
  "Feet Touch",
  "Plank",
];

const List<String> _back = [
  "Lat Pulldown",
  "Machine Row",
  "Cable Row",
  "Seated Row",
  "Chest Supported Row",
];

const List<String> _biceps = [
  "Seated Dumbbell Curl",
  "Hammer Curls",
  "Cable Curls",
];

const List<String> _chest = [
  "Chest Press",
  "Incline Press",
  "Flat Dumbbell Press",
  "Chest Flyes",
  "Cable Chest Press",
];

const List<String> _shoulders = [
  "Overhead Shoulder Press",
  "Arnold Dumbbell Press",
  "Lateral Raises",
  "Front Raises",
  "Shrugs",
];

const List<String> _triceps = [
  "Cable Pushdown",
  "Overhead Cable Extension",
  "Skull Crushers",
];

/// day number -> muscle group -> exercises
const Map<int, Map<String, List<String>>> workoutPlan = {
  1: {"Legs": _legs, "Abs": _abs},
  2: {"Back": _back, "Biceps": _biceps},
  3: {"Chest": _chest, "Shoulders": _shoulders},
  4: {"Triceps": _triceps, "Biceps": _biceps},
  5: {"Back": _back, "Legs": _legs},
  6: {"Shoulders": _shoulders, "Chest": _chest, "Triceps": _triceps},
};
