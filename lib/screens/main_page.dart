import 'package:flutter/material.dart';

import 'contact_list_screen.dart';

class MainPage extends StatefulWidget {
  final String myUserId;
  final Future<void> Function() onLogout;

  const MainPage({super.key, required this.myUserId, required this.onLogout});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shadow-Comm'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await widget.onLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_rounded,
              size: 80,
              color: Colors.deepPurple[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Shadow-Comm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Find a contact to start an encrypted conversation',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactListScreen(
                      myUserId: widget.myUserId,
                      onLogout: widget.onLogout,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Browse Contacts'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContactListScreen(
                myUserId: widget.myUserId,
                onLogout: widget.onLogout,
              ),
            ),
          );
        },
        tooltip: 'Find Contacts',
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.contacts),
      ),
    );
  }
}
