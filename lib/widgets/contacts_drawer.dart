import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactsDrawer extends StatelessWidget {
  final String myUserId;
  final void Function(String id, String name) onSelectContact;

  const ContactsDrawer({
    super.key,
    required this.myUserId,
    required this.onSelectContact,
  });

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Shadow Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: client
                    .from('profiles')
                    .select()
                    .neq('id', myUserId)
                    .order('shadow_name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading contacts: ${snapshot.error}'),
                    );
                  }

                  final profiles = snapshot.data ?? [];
                  if (profiles.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No other shadows yet.\nShare the app so friends can sign up!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      final name =
                          profile['shadow_name']?.toString() ?? 'Unknown';
                      final id = profile['id']?.toString() ?? '';

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          id.isNotEmpty
                              ? 'UUID: ${id.substring(0, 8)}...'
                              : 'No id',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: id.isEmpty
                            ? null
                            : () => onSelectContact(id, name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
