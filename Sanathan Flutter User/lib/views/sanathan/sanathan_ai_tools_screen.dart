import 'package:AstrowayCustomer/utils/services/sanathan_feature_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SanathanAiToolsScreen extends StatefulWidget {
  const SanathanAiToolsScreen({super.key});

  @override
  State<SanathanAiToolsScreen> createState() => _SanathanAiToolsScreenState();
}

class _SanathanAiToolsScreenState extends State<SanathanAiToolsScreen> {
  final TextEditingController searchController = TextEditingController();
  bool loading = true;
  String? error;
  String? aiStatusMessage;
  List<dynamic> tools = [];
  List<dynamic> categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadTools();
  }

  Future<void> loadTools() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final responses = await Future.wait([
        SanathanFeatureApi.getAiStatus(),
        SanathanFeatureApi.getAiTools(
          category: selectedCategory,
          search: searchController.text,
          perPage: 50,
        ),
      ]);
      final status = responses[0];
      final response = responses[1];
      setState(() {
        aiStatusMessage = status['ready'] == true
            ? null
            : 'Sanathan AI needs an active provider, model and API key before generation will work.';
        categories = response['categories'] ?? [];
        tools = response['tools']?['data'] ?? [];
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanathan AI Tools')),
      body: RefreshIndicator(
        onRefresh: loadTools,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search remedies, mantra, guidance...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: loadTools,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => loadTools(),
            ),
            const SizedBox(height: 12),
            if (aiStatusMessage != null) ...[
              _StateCard(message: aiStatusMessage!, icon: Icons.settings),
              const SizedBox(height: 12),
            ],
            if (categories.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categories[index - 1];
                    final slug = category?['slug']?.toString();
                    final selected = isAll
                        ? selectedCategory == null
                        : selectedCategory == slug;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(isAll ? 'All' : category['name'].toString()),
                      onSelected: (_) {
                        setState(() => selectedCategory = isAll ? null : slug);
                        loadTools();
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              _StateCard(message: error!, icon: Icons.error_outline)
            else if (tools.isEmpty)
              const _StateCard(
                message: 'No AI tools found.',
                icon: Icons.auto_awesome,
              )
            else
              ...tools.map((tool) => _ToolCard(tool: tool)).toList(),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final dynamic tool;

  @override
  Widget build(BuildContext context) {
    final title = tool['title']?.toString() ?? 'Sanathan AI Tool';
    final excerpt = tool['excerpt']?.toString() ?? '';
    final category = tool['category']?['name']?.toString() ??
        tool['category_name']?.toString() ??
        'AI Tool';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(
          () => SanathanAiToolDetailScreen(
            slug: tool['slug'].toString(),
            title: title,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text(category), visualDensity: VisualDensity.compact),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (excerpt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(excerpt, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              const Row(
                children: [
                  Text('Open tool'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SanathanAiToolDetailScreen extends StatefulWidget {
  const SanathanAiToolDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  State<SanathanAiToolDetailScreen> createState() =>
      _SanathanAiToolDetailScreenState();
}

class _SanathanAiToolDetailScreenState
    extends State<SanathanAiToolDetailScreen> {
  bool loading = true;
  bool generating = false;
  String? error;
  Map<String, dynamic>? tool;
  String? output;
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    loadTool();
  }

  Future<void> loadTool() async {
    try {
      final response = await SanathanFeatureApi.getAiTool(widget.slug);
      tool = Map<String, dynamic>.from(response['tool'] ?? {});
      for (final field in fields) {
        final name = _fieldName(field);
        if (name != null) {
          controllers.putIfAbsent(name, () => TextEditingController());
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get fields {
    final schema = tool?['form_schema'];
    if (schema is Map && schema['fields'] is List) {
      return List<Map<String, dynamic>>.from(
        (schema['fields'] as List).map(
          (field) => Map<String, dynamic>.from(field),
        ),
      );
    }
    return [];
  }

  Future<void> generate() async {
    final input = <String, dynamic>{};
    for (final entry in controllers.entries) {
      input[entry.key] = entry.value.text;
    }
    setState(() {
      generating = true;
      output = null;
    });
    try {
      final response = await SanathanFeatureApi.generateAiTool(
        widget.slug,
        input,
      );
      output = response['run']?['output']?.toString() ??
          response['message']?.toString() ??
          'Generated successfully.';
    } catch (e) {
      output = e.toString();
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _StateCard(message: error!, icon: Icons.error_outline)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      tool?['title']?.toString() ?? widget.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    if ((tool?['description']?.toString() ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(tool!['description'].toString()),
                      ),
                    const SizedBox(height: 18),
                    if (fields.isEmpty)
                      TextField(
                        controller: controllers.putIfAbsent(
                          'prompt',
                          () => TextEditingController(),
                        ),
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'What guidance do you need?',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      ...fields.map(_buildField),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: generating ? null : generate,
                      icon: generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Generate Guidance'),
                    ),
                    if (output != null) ...[
                      const SizedBox(height: 18),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(output!),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final name = _fieldName(field) ?? 'field';
    final label = field['label']?.toString() ?? name;
    final type = field['type']?.toString() ?? 'text';
    final options = field['options'];
    final controller = controllers.putIfAbsent(
      name,
      () => TextEditingController(),
    );

    if (type == 'textarea') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    if ((type == 'select' || type == 'dropdown') && options is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: controller.text.isEmpty ? null : controller.text,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: _optionValue(option),
                  child: Text(_optionLabel(option)),
                ),
              )
              .toList(),
          onChanged: (value) => controller.text = value ?? '',
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String? _fieldName(Map<String, dynamic> field) {
    return field['name']?.toString() ??
        field['fieldId']?.toString() ??
        field['id']?.toString();
  }

  String _optionValue(dynamic option) {
    if (option is Map) {
      return (option['value'] ?? option['label'] ?? option['text'] ?? '')
          .toString();
    }

    return option.toString();
  }

  String _optionLabel(dynamic option) {
    if (option is Map) {
      return (option['label'] ?? option['text'] ?? option['value'] ?? '')
          .toString();
    }

    return option.toString();
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
