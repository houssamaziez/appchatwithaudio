import 'dart:async';

import 'package:get/get.dart';

class ChatController extends GetxController {
  // TIME -----------------------------
  bool isPressed = false;
  double counter = 0.0;
  late Timer _timer;

  void startTimer() {
    isPressed = true;
    update();

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      counter += 0.1;
      update();
    });
  }

  void stopTimer() {
    _timer.cancel();
    update();
    isPressed = false;
    update();
    Get.back();
  }

  String formatTime(double timeInSeconds) {
    int minutes = timeInSeconds ~/ 60;
    double seconds = timeInSeconds % 60;
    return '$minutes:${seconds.toStringAsFixed(1)}';
  }

  // TIME -----------------------------
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
