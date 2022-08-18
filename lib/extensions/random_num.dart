import 'dart:math';

extension RandomInt on int {
  static int generateRandomNumber({int min = 0, required int max}) {
    final random = Random();
    return min + random.nextInt(max - min);
  }
}
