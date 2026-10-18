# Shadow-Comm Codebase Summary

## Overview

Shadow-Comm is a Flutter messaging prototype built with Dart. It provides account
registration and sign-in, user profiles and contact discovery, direct chats, and
text and image sharing. Supabase provides authentication, database access,
realtime message updates, and image storage.

## Application flow

1. `lib/main.dart` initializes Flutter, local notifications, and Supabase.
2. The app routes signed-out users to authentication. Signed-in users without a
   profile are prompted to choose a `shadow_name`; other users reach the main
   screen.
3. Contacts can be browsed and searched, or a friend's user ID can be entered
   directly. Contact IDs can also be shared using the platform share sheet.
4. A chat uses a user-entered room password to encrypt and decrypt messages.
   Realtime updates populate the conversation, and decrypted message text is
   cached in memory while the chat is open.

## Main code areas

- `lib/main.dart` is the entrypoint only: notifications (non-web) and Supabase
  initialization, then `runApp`.
- `lib/app.dart` holds `ShadowCommApp`, which routes to auth, profile setup, or
  the main page.
- `lib/screens/` holds full screens: `auth_screen`, `profile_setup_screen`,
  `main_page`, `contact_list_screen`, `chat_screen`.
- `lib/widgets/` holds reusable pieces: `message_bubble`, `message_input_bar`,
  `room_key_dialog`, plus the currently unused `chat_bubble` and
  `contacts_drawer`.
- `lib/services/chat_service.dart` handles message inserts and realtime message
  streams, and uploads images to Supabase Storage.
- `lib/services/security_service.dart` implements message encryption and
  decryption.
- `lib/services/notification_service.dart` initializes local notifications and
  displays notifications for incoming messages.
- `assets/images/` contains the launcher image used by the Flutter app and icon
  generation configuration.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/` contain Flutter
  platform projects and build configuration.
- `test/` contains the current automated tests.

## Message and storage design

`SecurityService` derives a 256-bit key from the room password with Argon2id,
using a fresh 16-byte salt. It encrypts with AES-GCM and a fresh 12-byte nonce.
The stored packet is laid out as salt, nonce, 16-byte authentication tag, and
ciphertext; `ChatService` base64-encodes that packet into the `messages.packet`
field.

The app expects a Supabase `profiles` table with `id` and `shadow_name` fields,
and a `messages` table with `id`, `sender_id`, `receiver_id`, `packet`, and
`created_at` fields. The chat service also expects a Storage bucket named
`snaps`. Message reads are streamed and limited to the 20 newest rows before
client-side filtering; the chat screen then selects the rows for the active
conversation.

Images are compressed on the device and uploaded to the `snaps` bucket. The
resulting public URL is encrypted as the chat message, but the image itself is
stored as an image file in Storage. The app therefore does not encrypt image
bytes before upload.

## Dependencies and configuration

The main dependencies are Flutter, `supabase_flutter`, `cryptography`,
`cryptography_plus`, `image_picker`, `flutter_image_compress`,
`cached_network_image`, `share_plus`, and `flutter_local_notifications`.
`pubspec.yaml` sets the Dart SDK constraint to `^3.10.7`.

Supabase initialization is in `lib/main.dart`; verify the project URL and
provide the correct public anon key for the target environment. The Supabase
tables, Storage bucket, access policies, and realtime settings must be available
for the app's backend operations to work.

## Tests and common commands

The repository includes `test/shadow_comm_test.dart` and
`test/widget_test.dart`. They are basic starter tests and do not currently
exercise the messaging, encryption, or Supabase flows.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
