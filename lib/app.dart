import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/main_page.dart';
import 'screens/profile_setup_screen.dart';

class ShadowCommApp extends StatefulWidget {
  const ShadowCommApp({super.key});

  @override
  State<ShadowCommApp> createState() => _ShadowCommAppState();
}

class _ShadowCommAppState extends State<ShadowCommApp> {
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: user == null
          ? AuthScreen(onAuthenticated: () => setState(() {}))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: client
                  .from('profiles')
                  .select()
                  .eq('id', user.id)
                  .limit(1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Profile load error: ${snapshot.error}'),
                    ),
                  );
                }

                final hasProfile =
                    snapshot.data != null && snapshot.data!.isNotEmpty;

                if (!hasProfile) {
                  return ProfileSetupScreen(onCompleted: () => setState(() {}));
                }

                final myShadowId = user.id;

                return MainPage(
                  myUserId: myShadowId,
                  onLogout: () async {
                    await client.auth.signOut();
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }
}
