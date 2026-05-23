import 'package:AstrowayCustomer/utils/global.dart' as global;
import 'package:AstrowayCustomer/utils/services/sanathan_feature_api.dart';
import 'package:AstrowayCustomer/views/sanathan/widgets/sanathan_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SanathanCoursesScreen extends StatefulWidget {
  const SanathanCoursesScreen({super.key});

  @override
  State<SanathanCoursesScreen> createState() => _SanathanCoursesScreenState();
}

class _SanathanCoursesScreenState extends State<SanathanCoursesScreen> {
  bool loading = true;
  String? error;
  List<dynamic> courses = [];

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await SanathanFeatureApi.getCourses(
        userId: global.currentUserId,
        perPage: 30,
      );
      setState(() => courses = response['courses']?['data'] ?? []);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SanathanScaffold(
      title: 'Sanathan Courses',
      body: RefreshIndicator(
        onRefresh: loadCourses,
        child: ListView(
          padding: const EdgeInsets.all(SanathanSpacing.md),
          children: [
            const GurujiPromptCard(
              title: 'Premium learning with Guruji',
              prompt:
                  'Premium at ₹99 unlocks live Sloka, Story, Yoga and Meditation classes, recordings and materials.',
            ),
            const SizedBox(height: SanathanSpacing.md),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              SanathanCard(
                child: Text(error!,
                    style: const TextStyle(color: SanathanColors.maroon)),
              )
            else if (courses.isEmpty)
              const SanathanCard(child: Text('No Sanathan courses found.'))
            else
              ...courses.map((course) => _CourseCard(course: course)),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final dynamic course;

  @override
  Widget build(BuildContext context) {
    final title = course['title']?.toString() ?? 'Sanathan Course';
    final image = course['image']?.toString();
    final teacher = course['teacher'] is Map ? course['teacher'] as Map : {};
    final locked = course['access_state'] == 'locked';

    return SanathanCard(
      margin: const EdgeInsets.only(bottom: SanathanSpacing.md),
      padding: EdgeInsets.zero,
      onTap: () => Get.to(() => SanathanCourseDetailScreen(
            courseId: int.tryParse(course['id'].toString()) ?? 0,
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: image == null || image.isEmpty
                ? Container(
                    height: 150,
                    color: SanathanColors.surfaceStrong,
                    child: const Center(
                      child: Icon(Icons.menu_book,
                          color: SanathanColors.saffron, size: 42),
                    ),
                  )
                : Image.network(
                    global.buildImageUrl(image),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(SanathanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SanathanChip(
                      label: course['category_name']?.toString() ?? 'Course',
                      icon: Icons.school_rounded,
                    ),
                    SanathanChip(
                      label: locked ? 'Premium ₹99' : 'Unlocked',
                      icon: locked ? Icons.lock_rounded : Icons.lock_open,
                    ),
                  ],
                ),
                const SizedBox(height: SanathanSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    color: SanathanColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course['description']?.toString() ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SanathanColors.muted),
                ),
                const SizedBox(height: SanathanSpacing.md),
                _InfoLine(
                  icon: Icons.person_rounded,
                  text: teacher['name']?.toString() ?? 'Sanathan Teacher',
                ),
                _InfoLine(
                  icon: Icons.schedule_rounded,
                  text: course['schedule_summary']?.toString() ??
                      'Weekly live class',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SanathanCourseDetailScreen extends StatefulWidget {
  const SanathanCourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<SanathanCourseDetailScreen> createState() =>
      _SanathanCourseDetailScreenState();
}

class _SanathanCourseDetailScreenState
    extends State<SanathanCourseDetailScreen> {
  bool loading = true;
  bool enrolling = false;
  String? error;
  Map<String, dynamic>? course;

  @override
  void initState() {
    super.initState();
    loadCourse();
  }

  Future<void> loadCourse() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await SanathanFeatureApi.getCourse(
        widget.courseId,
        userId: global.currentUserId,
      );
      setState(() => course = Map<String, dynamic>.from(response['course']));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> enroll() async {
    final userId = global.currentUserId;
    if (userId == null) {
      Get.snackbar('Sign in required', 'Please sign in to unlock this course.');
      return;
    }
    setState(() => enrolling = true);
    try {
      await SanathanFeatureApi.enrollCourse(
        widget.courseId,
        userId: userId,
        paymentType: 'premium',
      );
      await loadCourse();
    } catch (e) {
      Get.snackbar('Course', e.toString());
    } finally {
      if (mounted) setState(() => enrolling = false);
    }
  }

  Future<void> openLiveClass() async {
    final liveUrl = course?['live_youtube_url']?.toString();
    if (liveUrl == null || liveUrl.isEmpty) {
      Get.snackbar('Course', 'The live class link will be shared soon.');
      return;
    }

    final uri = Uri.tryParse(liveUrl);
    if (uri == null) {
      Get.snackbar('Course', 'The live class link is not valid yet.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar('Course', 'Could not open the live class link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = course;
    return SanathanScaffold(
      title: item?['title']?.toString() ?? 'Course',
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(SanathanSpacing.md),
                  children: [
                    _detailHeader(item!),
                    const SizedBox(height: SanathanSpacing.md),
                    _teacherCard(item['teacher'] is Map ? item['teacher'] : {}),
                    const SizedBox(height: SanathanSpacing.md),
                    _materialsCard(item),
                    const SizedBox(height: SanathanSpacing.md),
                    _lessons(item),
                  ],
                ),
      bottomNavigationBar: item == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(SanathanSpacing.md),
              child: SanathanPrimaryButton(
                loading: enrolling,
                icon: item['access_state'] == 'locked'
                    ? Icons.lock_open_rounded
                    : Icons.play_circle_fill_rounded,
                label: item['access_state'] == 'locked'
                    ? 'Unlock with Premium ₹99'
                    : 'Join Live Class',
                onPressed:
                    item['access_state'] == 'locked' ? enroll : openLiveClass,
              ),
            ),
    );
  }

  Widget _detailHeader(Map<String, dynamic> item) {
    return SanathanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title']?.toString() ?? 'Sanathan Course',
            style: const TextStyle(
              color: SanathanColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(item['description']?.toString() ?? ''),
          const SizedBox(height: SanathanSpacing.md),
          _InfoLine(
            icon: Icons.live_tv_rounded,
            text: item['schedule_summary']?.toString() ?? 'Weekly live class',
          ),
          _InfoLine(
            icon: Icons.people_alt_rounded,
            text: item['audience']?.toString() ?? 'All seekers',
          ),
        ],
      ),
    );
  }

  Widget _teacherCard(Map teacher) {
    return SanathanFeatureTile(
      icon: Icons.person_rounded,
      title: teacher['name']?.toString() ?? 'Sanathan Teacher',
      subtitle: teacher['bio']?.toString() ??
          teacher['title']?.toString() ??
          'Guided by Sanathan teachers.',
    );
  }

  Widget _materialsCard(Map<String, dynamic> item) {
    final outcomes = item['outcomes'] is List ? item['outcomes'] as List : [];
    return SanathanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Materials and outcomes',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(item['material_summary']?.toString() ??
              'Course materials will be added by Sanathan admin.'),
          ...outcomes.map((outcome) => _InfoLine(
                icon: Icons.check_circle_rounded,
                text: outcome.toString(),
              )),
        ],
      ),
    );
  }

  Widget _lessons(Map<String, dynamic> item) {
    final chapters = item['chapters'] is List ? item['chapters'] as List : [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Classes and recordings',
            style: TextStyle(
                color: SanathanColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: SanathanSpacing.sm),
        ...chapters.map((chapter) => SanathanFeatureTile(
              icon: chapter['lesson_type'] == 'live'
                  ? Icons.live_tv_rounded
                  : Icons.play_circle_fill_rounded,
              title: chapter['title']?.toString() ?? 'Class',
              subtitle: chapter['is_unlocked'] == true
                  ? (chapter['description']?.toString() ?? '')
                  : 'Locked for Premium members. Guruji recommends Premium ₹99 for full access.',
            )),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SanathanColors.saffron, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
