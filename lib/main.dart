import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // 1. Logic: Ignition
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize native notifications
  if (!kIsWeb) {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
  }

  // 3. Logic: Connect to your specific cloud building
  await Supabase.initialize(
    url: 'https://plwwwnozkyaaekwsrlps.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsd3d3bm96a3lhYWVrd3NybHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MzgxODksImV4cCI6MjA4OTQxNDE4OX0.R4GmCEP0uqK-X1-T8e3j98uW6BfLb0P46rufLuFfwUk',
  );

  runApp(const ShadowCommApp());
}
