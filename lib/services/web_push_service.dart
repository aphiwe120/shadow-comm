import 'package:flutter/foundation.dart';

import 'web_push_stub.dart' if (dart.library.js) 'web_push_web.dart' as impl;

/// Triggers the OneSignal helpers defined in web/index.html (web only).
void registerWebPush(String userId) {
  if (!kIsWeb) return;
  try {
    // Browser's native "Allow Notifications" prompt.
    impl.promptWebPush();
    // Link this browser to the Supabase user ID.
    impl.loginWebPush(userId);
  } catch (e) {
    debugPrint('Web push registration failed: $e');
  }
}
