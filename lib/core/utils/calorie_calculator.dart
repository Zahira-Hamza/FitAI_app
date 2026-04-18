class CalorieCalculator {
  static double estimateFromSets(int totalSets, int avgReps) {
    return totalSets * avgReps * 0.5;
  }

  static double estimateFromDuration(int durationSeconds) {
    return (durationSeconds / 60) * 7;
  }
}
