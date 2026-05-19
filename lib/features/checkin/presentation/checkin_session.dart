import 'package:flutter/foundation.dart';

class CheckinSession {
  CheckinSession._();

  static final ValueNotifier<bool> checkedIn = ValueNotifier<bool>(false);

  static void markCheckedIn() {
    checkedIn.value = true;
  }

  static void reset() {
    checkedIn.value = false;
  }
}
