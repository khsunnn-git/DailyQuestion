import "package:flutter/foundation.dart";

class UserProfileEvents {
  UserProfileEvents._();

  static final ValueNotifier<int> nicknameRevision = ValueNotifier<int>(0);

  static void notifyNicknameChanged() {
    nicknameRevision.value += 1;
  }
}
