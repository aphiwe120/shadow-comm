import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_screen.dart';
import 'profile_screen.dart';
import '../widgets/user_avatar.dart';

class ContactListScreen extends StatefulWidget {
  final String myUserId;
  final Future<void> Function() onLogout;

  const ContactListScreen({
    super.key,
    required this.myUserId,
    required this.onLogout,
  });

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualAddController = TextEditingController();

  // Simple in‑memory list of recently opened chats (not persisted).
  final List<Map<String, String>> _recentChats = [];

  @override
  void dispose() {
    _searchController.dispose();
    _manualAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shadow Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share my Shadow ID',
            onPressed: () async {
              final msg =
                  'Join me on Shadow-Comm! My ID is: ${widget.myUserId}';
              await SharePlus.instance.share(
                ShareParams(text: msg, subject: 'Shadow-Comm ID'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.onLogout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search shadows...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualAddController,
                    decoration: const InputDecoration(
                      hintText: 'Paste a friend\'s UID to start a chat...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final raw = _manualAddController.text.trim();
                    if (raw.isEmpty) return;

                    final id = raw;
                    final namePreview =
                        'Shadow ${id.length >= 8 ? id.substring(0, 8) : id}';

                    // Track in recent chats (in memory only).
                    _recentChats.removeWhere((c) => c['id'] == id);
                    _recentChats.insert(0, {'id': id, 'name': namePreview});

                    _manualAddController.clear();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          myUserId: widget.myUserId,
                          receiverId: id,
                          receiverName: namePreview,
                        ),
                      ),
                    );
                  },
                  child: const Text('Manual Add'),
                ),
              ],
            ),
          ),
          if (_recentChats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent chats',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            ),
          if (_recentChats.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                itemCount: _recentChats.length,
                itemBuilder: (context, index) {
                  final chat = _recentChats[index];
                  final id = chat['id']!;
                  final name = chat['name']!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(name),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              myUserId: widget.myUserId,
                              receiverId: id,
                              receiverName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: client
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .neq('id', widget.myUserId)
                  .order('shadow_name')
                  .map((event) => event.cast<Map<String, dynamic>>()),
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
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? profiles
                    : profiles.where((p) {
                        final name = (p['shadow_name'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(query);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No matching shadows found.'),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final profile = filtered[index];
                    final name =
                        profile['shadow_name']?.toString() ?? 'Unknown';
                    final id = profile['id']?.toString() ?? '';
                    final avatarUrl = profile['avatar_url']?.toString();

                    return ListTile(
                      leading: UserAvatar(avatarUrl: avatarUrl),
                      title: Text(name),
                      subtitle: Text(
                        id.isNotEmpty
                            ? 'UUID: ${id.substring(0, 8)}...'
                            : 'No id',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: id.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    myUserId: widget.myUserId,
                                    receiverId: id,
                                    receiverName: name,
                                    receiverAvatarUrl: avatarUrl,
                                  ),
                                ),
                              );
                            },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
