import 'package:AstrowayCustomer/utils/global.dart' as global;
import 'package:AstrowayCustomer/utils/services/sanathan_feature_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalGurujiScreen extends StatefulWidget {
  const PersonalGurujiScreen({super.key});

  @override
  State<PersonalGurujiScreen> createState() => _PersonalGurujiScreenState();
}

class _PersonalGurujiScreenState extends State<PersonalGurujiScreen> {
  static const _sessionKey = 'sanathan_guruji_guest_session_id';

  final messageController = TextEditingController();
  final nameController = TextEditingController();
  final birthDateController = TextEditingController();
  final birthTimeController = TextEditingController();
  final birthPlaceController = TextEditingController();

  bool loading = true;
  bool sending = false;
  bool showBirthDetails = false;
  String? guestSessionId;
  List<Map<String, String>> messages = [];
  List<dynamic> suggestedActions = [];

  @override
  void initState() {
    super.initState();
    boot();
  }

  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();
    guestSessionId = prefs.getString(_sessionKey);
    try {
      final response = await SanathanFeatureApi.getGurujiWelcome(
        guestSessionId: guestSessionId,
        userId: global.currentUserId,
      );
      await saveSession(response);
      final welcome = response['welcome'] ?? {};
      final history = await SanathanFeatureApi.getGurujiHistory(
        guestSessionId: guestSessionId,
        userId: global.currentUserId,
      );
      final historyMessages = (history['messages'] as List?)
              ?.map(
                (message) => {
                  'role': message['role']?.toString() ?? 'assistant',
                  'content': message['content']?.toString() ?? '',
                },
              )
              .where((message) => (message['content'] ?? '').isNotEmpty)
              .toList() ??
          [];
      setState(() {
        messages = historyMessages.isNotEmpty
            ? historyMessages
            : [
                {
                  'role': 'assistant',
                  'content':
                      welcome['message']?.toString() ??
                      'Namaste. I am your Sanathan Guruji.',
                },
              ];
        suggestedActions = welcome['suggested_actions'] ?? [];
      });
    } catch (e) {
      setState(() {
        messages = [
          {'role': 'assistant', 'content': e.toString()},
        ];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveSession(Map<String, dynamic> response) async {
    final session = response['guest_session_id']?.toString();
    if (session != null && session.isNotEmpty) {
      guestSessionId = session;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, session);
    }
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || sending) return;

    setState(() {
      sending = true;
      messageController.clear();
      messages.add({'role': 'user', 'content': message});
      messages.add({'role': 'assistant', 'content': 'Guruji is reflecting...'});
    });

    try {
      final response = await SanathanFeatureApi.chatWithGuruji(
        message,
        guestSessionId: guestSessionId,
        userId: global.currentUserId,
      );
      await saveSession(response);
      setState(() {
        messages[messages.length - 1] = {
          'role': 'assistant',
          'content':
              response['message']?.toString() ??
              'I am here. Please ask again in a little more detail.',
        };
        suggestedActions = response['suggested_actions'] ?? [];
      });
    } catch (e) {
      setState(() {
        messages[messages.length - 1] = {
          'role': 'assistant',
          'content': e.toString(),
        };
      });
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> saveBirthDetails() async {
    final payload = {
      if (guestSessionId != null) 'guest_session_id': guestSessionId,
      if (global.currentUserId != null) 'user_id': global.currentUserId,
      'name': nameController.text,
      'birth_date': birthDateController.text,
      'birth_time': birthTimeController.text,
      'birth_place': birthPlaceController.text,
    };

    try {
      final response = await SanathanFeatureApi.updateGurujiProfile(
        payload,
        guestSessionId: guestSessionId,
      );
      await saveSession(response);
      setState(() {
        showBirthDetails = false;
        messages.add({
          'role': 'assistant',
          'content':
              'Birth details saved. Premium Rs.99 keeps your plan, reminders and deeper guidance available.',
        });
      });
    } catch (e) {
      setState(() {
        messages.add({'role': 'assistant', 'content': e.toString()});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Guruji')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _PremiumStrip(
              title: 'Premium personal plan',
              subtitle: 'Kundali memory, live classes, daily reminders.',
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _ChatBubble(
                        text: message['content'] ?? '',
                        isUser: message['role'] == 'user',
                      );
                    },
                  ),
          ),
          if (suggestedActions.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: suggestedActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = suggestedActions[index];
                  return ActionChip(
                    label: Text(action['label']?.toString() ?? 'Open'),
                    onPressed: () {
                      if (action['type'] == 'birth_details') {
                        setState(() => showBirthDetails = !showBirthDetails);
                      } else {
                        sendMessage(action['label']?.toString() ?? '');
                      }
                    },
                  );
                },
              ),
            ),
          if (showBirthDetails)
            _BirthDetailsForm(
              nameController: nameController,
              birthDateController: birthDateController,
              birthTimeController: birthTimeController,
              birthPlaceController: birthPlaceController,
              onSave: saveBirthDetails,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ask Guruji anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onSubmitted: sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: sending
                        ? null
                        : () => sendMessage(messageController.text),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthDetailsForm extends StatelessWidget {
  const _BirthDetailsForm({
    required this.nameController,
    required this.birthDateController,
    required this.birthTimeController,
    required this.birthPlaceController,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController birthDateController;
  final TextEditingController birthTimeController;
  final TextEditingController birthPlaceController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Birth date YYYY-MM-DD',
                ),
              ),
              TextField(
                controller: birthTimeController,
                decoration: const InputDecoration(
                  labelText: 'Birth time HH:mm',
                ),
              ),
              TextField(
                controller: birthPlaceController,
                decoration: const InputDecoration(labelText: 'Birth place'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onSave,
                child: const Text('Save birth details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF8F101D) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFD5B5)),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _PremiumStrip extends StatelessWidget {
  const _PremiumStrip({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFD5B5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8F101D),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Rs.99',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
