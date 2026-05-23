import 'package:AstrowayCustomer/utils/global.dart' as global;
import 'package:AstrowayCustomer/utils/services/sanathan_feature_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SanathanListingsScreen extends StatefulWidget {
  const SanathanListingsScreen({super.key});

  @override
  State<SanathanListingsScreen> createState() => _SanathanListingsScreenState();
}

class _SanathanListingsScreenState extends State<SanathanListingsScreen> {
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  String? selectedCategory;
  List<dynamic> categories = [];
  List<dynamic> listings = [];

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final categoryResponse = await SanathanFeatureApi.getListingCategories();
      final listingResponse = await SanathanFeatureApi.getListings(
        category: selectedCategory,
        search: searchController.text,
        perPage: 30,
      );

      setState(() {
        categories =
            categoryResponse['categories'] ?? categoryResponse['recordList'] ?? [];
        listings =
            listingResponse['listings']?['data'] ??
            listingResponse['recordList'] ??
            [];
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
      appBar: AppBar(title: const Text('Sanathan Listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Get.to<bool>(
            () => SanathanListingSubmitScreen(categories: categories),
          );
          if (created == true) {
            loadListings();
          }
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Submit'),
      ),
      body: RefreshIndicator(
        onRefresh: loadListings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PremiumStrip(
              title: 'Premium member benefits',
              subtitle: 'Better recommendations and class access.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search temples, yoga, puja, shops...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: loadListings,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => loadListings(),
            ),
            const SizedBox(height: 12),
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
                        loadListings();
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
            else if (listings.isEmpty)
              const _StateCard(
                message: 'No listings found yet.',
                icon: Icons.account_balance,
              )
            else
              ...listings.map((listing) => _ListingCard(listing: listing)),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final dynamic listing;

  @override
  Widget build(BuildContext context) {
    final title = listing['title']?.toString() ?? 'Sanathan Listing';
    final type = listing['type']?.toString() ?? 'Service';
    final city = listing['city']?.toString() ?? '';
    final state = listing['state']?.toString() ?? '';
    final summary =
        listing['short_description']?.toString() ??
        listing['description']?.toString() ??
        '';
    final verified =
        listing['is_verified'] == 1 || listing['is_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(
          () => SanathanListingDetailScreen(
            slug: listing['slug'].toString(),
            title: title,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (verified)
                    const Icon(Icons.verified, color: Color(0xFF176445)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  type,
                  city,
                  state,
                ].where((item) => item.isNotEmpty).join(' - '),
                style: const TextStyle(color: Color(0xFF816352)),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SanathanListingDetailScreen extends StatefulWidget {
  const SanathanListingDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  State<SanathanListingDetailScreen> createState() =>
      _SanathanListingDetailScreenState();
}

class _SanathanListingDetailScreenState
    extends State<SanathanListingDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? listing;

  @override
  void initState() {
    super.initState();
    loadListing();
  }

  Future<void> loadListing() async {
    try {
      final response = await SanathanFeatureApi.getListing(widget.slug);
      listing = Map<String, dynamic>.from(
        response['listing'] ?? response['recordList'] ?? {},
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = listing;
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
                  item?['title']?.toString() ?? widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    item?['type']?.toString() ?? '',
                    item?['city']?.toString() ?? '',
                    item?['state']?.toString() ?? '',
                  ].where((part) => part.isNotEmpty).join(' - '),
                  style: const TextStyle(color: Color(0xFF816352)),
                ),
                const SizedBox(height: 14),
                _PremiumStrip(
                  title: 'Ask Guruji if this is right for you',
                  subtitle: 'Premium Rs.99 adds better recommendations.',
                ),
                const SizedBox(height: 14),
                if ((item?['description']?.toString() ?? '').isNotEmpty)
                  Text(item!['description'].toString()),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Contact / Enquire'),
                ),
              ],
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

class SanathanListingSubmitScreen extends StatefulWidget {
  const SanathanListingSubmitScreen({super.key, required this.categories});

  final List<dynamic> categories;

  @override
  State<SanathanListingSubmitScreen> createState() =>
      _SanathanListingSubmitScreenState();
}

class _SanathanListingSubmitScreenState
    extends State<SanathanListingSubmitScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final businessController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  final tagsController = TextEditingController();
  bool submitting = false;
  int? categoryId;
  String type = 'temple';

  @override
  void dispose() {
    titleController.dispose();
    businessController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    stateController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || submitting) return;

    setState(() => submitting = true);
    try {
      final response = await SanathanFeatureApi.createListing({
        if (global.currentUserId != null) 'user_id': global.currentUserId,
        if (categoryId != null) 'category_id': categoryId,
        'title': titleController.text.trim(),
        'business_name': businessController.text.trim(),
        'type': type,
        'short_description': descriptionController.text.trim(),
        'description': descriptionController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'website': websiteController.text.trim(),
        'service_tags': tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
      });

      final success = response['success'] == true || response['status'] == 200;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                (success
                    ? 'Listing submitted for approval.'
                    : 'Unable to submit listing.'),
          ),
        ),
      );

      if (success) {
        Get.back(result: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Listing')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem<int>(
                        value: int.tryParse(category['id'].toString()),
                        child: Text(category['name']?.toString() ?? ''),
                      ),
                    )
                    .where((item) => item.value != null)
                    .toList(),
                onChanged: (value) => setState(() => categoryId = value),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Listing type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'temple', child: Text('Temple')),
                DropdownMenuItem(value: 'puja', child: Text('Puja Service')),
                DropdownMenuItem(value: 'yoga', child: Text('Yoga/Meditation')),
                DropdownMenuItem(value: 'shop', child: Text('Spiritual Shop')),
                DropdownMenuItem(value: 'seva', child: Text('Seva/Community')),
              ],
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            const SizedBox(height: 12),
            _formField(
              controller: titleController,
              label: 'Listing title',
              isRequired: true,
            ),
            _formField(controller: businessController, label: 'Business name'),
            _formField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 4,
              isRequired: true,
            ),
            _formField(controller: cityController, label: 'City'),
            _formField(controller: stateController, label: 'State'),
            _formField(controller: phoneController, label: 'Phone'),
            _formField(controller: emailController, label: 'Email'),
            _formField(controller: websiteController, label: 'Website'),
            _formField(
              controller: tagsController,
              label: 'Tags, separated by commas',
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: submitting ? null : submit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: isRequired
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
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
