import 'package:astrowaypartner/services/sanathan_feature_api.dart';
import 'package:astrowaypartner/utils/global.dart' as global;
import 'package:flutter/material.dart';

class SanathanPartnerHubScreen extends StatefulWidget {
  const SanathanPartnerHubScreen({super.key});

  @override
  State<SanathanPartnerHubScreen> createState() =>
      _SanathanPartnerHubScreenState();
}

class _SanathanPartnerHubScreenState extends State<SanathanPartnerHubScreen> {
  final messageController = TextEditingController();
  bool loading = true;
  bool sending = false;
  String gurujiMessage = '';
  String? aiStatusMessage;
  List<dynamic> aiTools = [];
  List<dynamic> courses = [];
  List<dynamic> listings = [];
  List<dynamic> myListings = [];
  List<Map<String, String>> chat = [];

  @override
  void initState() {
    super.initState();
    loadHub();
  }

  Future<void> loadHub() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        SanathanFeatureApi.getGurujiWelcome(userId: global.currentUserId),
        SanathanFeatureApi.getAiStatus(),
        SanathanFeatureApi.getAiTools(perPage: 6),
        SanathanFeatureApi.getCourses(perPage: 4),
        SanathanFeatureApi.getListings(perPage: 6),
        global.currentUserId == null
            ? Future.value({'recordList': []})
            : SanathanFeatureApi.getMyListings(
                userId: global.currentUserId!,
                perPage: 6,
              ),
      ]);

      final welcome = results[0]['welcome'] ?? {};
      setState(() {
        gurujiMessage = welcome['message']?.toString() ??
            'Namaste. Sanathan Guruji is ready to guide users.';
        aiStatusMessage = results[1]['ready'] == true
            ? null
            : 'Sanathan AI needs provider, model and API key setup.';
        aiTools = results[2]['tools']?['data'] ?? [];
        courses =
            results[3]['courses']?['data'] ?? results[3]['recordList'] ?? [];
        listings =
            results[4]['listings']?['data'] ?? results[4]['recordList'] ?? [];
        myListings =
            results[5]['listings']?['data'] ?? results[5]['recordList'] ?? [];
        chat = [
          {'role': 'assistant', 'content': gurujiMessage},
        ];
      });
    } catch (e) {
      setState(() {
        gurujiMessage = e.toString();
        chat = [
          {'role': 'assistant', 'content': gurujiMessage},
        ];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendGurujiMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
      chat.add({'role': 'user', 'content': text});
      messageController.clear();
    });

    try {
      final response = await SanathanFeatureApi.chatWithGuruji(
        text,
        userId: global.currentUserId,
        context: {'source': 'guruji_flutter_app'},
      );
      final reply = response['reply']?.toString() ??
          'I will help you guide this user with Sanathan wisdom.';
      setState(() => chat.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      setState(() => chat.add({'role': 'assistant', 'content': e.toString()}));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanathan Tools')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadHub,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _premiumCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('Live Sanathan Courses'),
                  ...courses.map((course) => _courseTile(course)),
                  if (courses.isEmpty)
                    _emptyTile('No official Sanathan courses available yet.'),
                  const SizedBox(height: 14),
                  _gurujiCard(),
                  const SizedBox(height: 14),
                  _sectionTitle('My Listings'),
                  ...myListings.map(
                    (listing) => _simpleTile(
                      icon: Icons.assignment_turned_in,
                      title:
                          listing['title']?.toString() ?? 'Submitted Listing',
                      subtitle: [
                        listing['status']?.toString() ?? '',
                        listing['type']?.toString() ?? '',
                        listing['city']?.toString() ?? '',
                      ].where((part) => part.isNotEmpty).join(' - '),
                    ),
                  ),
                  if (myListings.isEmpty)
                    _emptyTile('No submitted listings yet.'),
                  const SizedBox(height: 14),
                  if (aiStatusMessage != null) ...[
                    _emptyTile(aiStatusMessage!),
                    const SizedBox(height: 14),
                  ],
                  _sectionTitle('AI Tools'),
                  ...aiTools.map(
                    (tool) => _simpleTile(
                      icon: Icons.auto_fix_high,
                      title: tool['title']?.toString() ?? 'AI Tool',
                      subtitle: tool['excerpt']?.toString() ??
                          tool['description']?.toString() ??
                          'Generate guidance using Sanathan AI.',
                    ),
                  ),
                  if (aiTools.isEmpty) _emptyTile('No AI tools available yet.'),
                  const SizedBox(height: 14),
                  _sectionTitle('Listings'),
                  ...listings.map(
                    (listing) => _simpleTile(
                      icon: Icons.store,
                      title: listing['title']?.toString() ?? 'Listing',
                      subtitle:
                          [listing['type'], listing['city'], listing['state']]
                              .where(
                                (part) =>
                                    part != null && part.toString().isNotEmpty,
                              )
                              .join(' - '),
                    ),
                  ),
                  if (listings.isEmpty)
                    _emptyTile('No listings available yet.'),
                ],
              ),
            ),
    );
  }

  Widget _premiumCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF8F1019), Color(0xFFF17605)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promote Premium at ₹99',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use Guruji guidance to explain premium classes, reports, AI tools and saved kundali benefits.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _gurujiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Personal Guruji'),
            ...chat.map(
              (message) => Align(
                alignment: message['role'] == 'user'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: message['role'] == 'user'
                        ? const Color(0xFF8F1019)
                        : const Color(0xFFFFF7EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: message['role'] == 'user'
                          ? Colors.white
                          : const Color(0xFF32120F),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ask Guruji how to guide a user...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: sending ? null : sendGurujiMessage,
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6F0F18),
        ),
      ),
    );
  }

  Widget _simpleTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF0D8),
          child: Icon(icon, color: const Color(0xFFE96005)),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle.isEmpty ? 'Sanathan feature' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _courseTile(dynamic course) {
    final teacher = course['teacher'] is Map ? course['teacher'] as Map : {};
    final schedule = [
      course['schedule_summary']?.toString() ?? '',
      course['live_day']?.toString() ?? '',
      course['live_time']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(' - ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFF0D8),
                  child: Icon(Icons.school_rounded, color: Color(0xFFE96005)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title']?.toString() ??
                            course['name']?.toString() ??
                            'Sanathan Course',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF32120F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['category_name']?.toString() ??
                            'Premium live class',
                        style: const TextStyle(color: Color(0xFF8A5A43)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '₹99',
                    style: TextStyle(
                      color: Color(0xFF8F1019),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course['description']?.toString() ??
                  'Official Sanathan premium course.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 10),
            _miniInfo(Icons.person_rounded,
                teacher['name']?.toString() ?? 'Sanathan Teacher'),
            _miniInfo(Icons.schedule_rounded,
                schedule.isEmpty ? 'Weekly YouTube Live class' : schedule),
            _miniInfo(
              Icons.lock_rounded,
              course['premium_message']?.toString() ??
                  'Premium members get live class, recordings and materials.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE96005)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _emptyTile(String text) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
    );
  }
}
