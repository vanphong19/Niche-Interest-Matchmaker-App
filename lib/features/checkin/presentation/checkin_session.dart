import 'package:flutter/foundation.dart';

class CheckinSession {
  CheckinSession._();

  static final ValueNotifier<bool> checkedIn = ValueNotifier<bool>(false);
  static final ValueNotifier<Set<String>> checkedInMatchIds =
      ValueNotifier<Set<String>>(<String>{});

  static bool isCheckedIn(String? matchId) {
    final id = matchId?.trim();
    if (id == null || id.isEmpty) return checkedIn.value;
    return checkedInMatchIds.value.contains(id);
  }

  static void markCheckedIn([String? matchId]) {
    final id = matchId?.trim();
    if (id != null && id.isNotEmpty) {
      checkedInMatchIds.value = {...checkedInMatchIds.value, id};
    }
    checkedIn.value = true;
  }

  static void reset() {
    checkedIn.value = false;
    checkedInMatchIds.value = <String>{};
  }
}
