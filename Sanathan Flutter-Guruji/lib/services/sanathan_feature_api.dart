import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/config.dart';

class SanathanFeatureApi {
  static String get _apiBase {
    final apiUrl = appParameters[appMode]['apiUrl'] as String;
    return apiUrl.endsWith('/')
        ? apiUrl.substring(0, apiUrl.length - 1)
        : apiUrl;
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{};

    query?.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        params[key] = value.toString();
      }
    });

    return Uri.parse(
      '$_apiBase$normalizedPath',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAiTools({
    String? category,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      _uri('/sanathan-ai-tools', {
        'category': category,
        's': search,
        'page': page,
        'per_page': perPage,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getAiTool(String slug) async {
    final response = await http.get(_uri('/sanathan-ai-tools/$slug'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getAiStatus() async {
    final response = await http.get(_uri('/sanathan-ai-tools/status'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> generateAiTool(
    String slug,
    Map<String, dynamic> input,
  ) async {
    final response = await http.post(
      _uri('/sanathan-ai-tools/$slug/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getAiToolRuns({
    int? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      _uri('/sanathan-ai-tools/runs', {
        if (userId != null) 'user_id': userId,
        'page': page,
        'per_page': perPage,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getListingCategories() async {
    final response = await http.get(_uri('/sanathan-listing-categories'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getCourseCategories() async {
    final response = await http.get(_uri('/sanathan-course-categories'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getCourses({
    int? categoryId,
    String? search,
    int? userId,
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await http.get(
      _uri('/sanathan-courses', {
        'category_id': categoryId,
        's': search,
        'user_id': userId,
        'page': page,
        'per_page': perPage,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getCourse(
    int id, {
    int? userId,
  }) async {
    final response = await http.get(
      _uri('/sanathan-courses/$id', {
        'user_id': userId,
      }),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyCourses({
    required int userId,
  }) async {
    final response = await http.get(
      _uri('/sanathan-courses/mine', {
        'user_id': userId,
      }),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> enrollCourse(
    int id, {
    required int userId,
    String paymentType = 'free',
  }) async {
    final response = await http.post(
      _uri('/sanathan-courses/$id/enroll'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'payment_type': paymentType,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> saveCourseProgress(
    int id, {
    required int userId,
    int? chapterId,
    String status = 'in_progress',
    int progressPercent = 0,
    int watchSeconds = 0,
  }) async {
    final response = await http.post(
      _uri('/sanathan-courses/$id/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        if (chapterId != null) 'chapter_id': chapterId,
        'status': status,
        'progress_percent': progressPercent,
        'watch_seconds': watchSeconds,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getListings({
    String? category,
    String? type,
    String? search,
    String? city,
    String? state,
    bool? featured,
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await http.get(
      _uri('/sanathan-listings', {
        'category': category,
        'type': type,
        's': search,
        'city': city,
        'state': state,
        'featured': featured == null ? null : (featured ? 1 : 0),
        'page': page,
        'per_page': perPage,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getListing(String slug) async {
    final response = await http.get(_uri('/sanathan-listings/$slug'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyListings({
    required int userId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await http.get(
      _uri('/sanathan-listings/mine', {
        'user_id': userId,
        'status': status,
        'page': page,
        'per_page': perPage,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> createListing(
    Map<String, dynamic> input,
  ) async {
    final response = await http.post(
      _uri('/sanathan-listings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getGurujiWelcome({
    String? guestSessionId,
    int? userId,
  }) async {
    final response = await http.post(
      _uri('/sanathan-guruji/welcome'),
      headers: _jsonHeaders(guestSessionId),
      body: jsonEncode({
        if (guestSessionId != null && guestSessionId.isNotEmpty)
          'guest_session_id': guestSessionId,
        if (userId != null) 'user_id': userId,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> updateGurujiProfile(
    Map<String, dynamic> input, {
    String? guestSessionId,
  }) async {
    final response = await http.post(
      _uri('/sanathan-guruji/profile/update'),
      headers: _jsonHeaders(guestSessionId),
      body: jsonEncode(input),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> chatWithGuruji(
    String message, {
    String? guestSessionId,
    int? userId,
    Map<String, dynamic>? context,
  }) async {
    final response = await http.post(
      _uri('/sanathan-guruji/chat'),
      headers: _jsonHeaders(guestSessionId),
      body: jsonEncode({
        'message': message,
        if (guestSessionId != null && guestSessionId.isNotEmpty)
          'guest_session_id': guestSessionId,
        if (userId != null) 'user_id': userId,
        ...?context,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> updateListing(
    int id,
    Map<String, dynamic> input,
  ) async {
    final response = await http.post(
      _uri('/sanathan-listings/$id/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> deleteListing(
    int id, {
    required int userId,
  }) async {
    final response = await http.post(
      _uri('/sanathan-listings/$id/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getListingPaymentOptions(int id) async {
    final response = await http.get(_uri('/sanathan-listings/$id/payment-options'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> createListingPayment(
    int id, {
    required int userId,
    required String purpose,
    double? amount,
    String? currency,
    String paymentMode = 'online',
    String? returnUrl,
    String? notes,
    Map<String, dynamic>? meta,
  }) async {
    final response = await http.post(
      _uri('/sanathan-listings/$id/payment-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'purpose': purpose,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        'payment_mode': paymentMode,
        if (returnUrl != null) 'return_url': returnUrl,
        if (notes != null) 'notes': notes,
        if (meta != null) 'meta': meta,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> confirmListingPayment(
    int id, {
    required int userId,
    required int listingPaymentId,
    String status = 'success',
    String? paymentReference,
    String? gatewayReference,
  }) async {
    final response = await http.post(
      _uri('/sanathan-listings/$id/payment-confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'listing_payment_id': listingPaymentId,
        'status': status,
        if (paymentReference != null) 'payment_reference': paymentReference,
        if (gatewayReference != null) 'gateway_reference': gatewayReference,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getListingVerificationStatus(int id) async {
    final response =
        await http.get(_uri('/sanathan-listings/$id/verification-status'));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> requestListingVerification(
    int id, {
    required int userId,
    required String identityName,
    String? businessRegistrationNumber,
    List<Map<String, dynamic>> documents = const [],
    String? notes,
  }) async {
    final response = await http.post(
      _uri('/sanathan-listings/$id/verification-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'identity_name': identityName,
        if (businessRegistrationNumber != null)
          'business_registration_number': businessRegistrationNumber,
        'documents': documents,
        if (notes != null) 'notes': notes,
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getGurujiHistory({
    String? guestSessionId,
    int? userId,
    int limit = 30,
  }) async {
    final response = await http.post(
      _uri('/sanathan-guruji/history'),
      headers: _jsonHeaders(guestSessionId),
      body: jsonEncode({
        if (guestSessionId != null && guestSessionId.isNotEmpty)
          'guest_session_id': guestSessionId,
        if (userId != null) 'user_id': userId,
        'limit': limit,
      }),
    );

    return _decode(response);
  }

  static Map<String, String> _jsonHeaders(String? guestSessionId) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (guestSessionId != null && guestSessionId.isNotEmpty)
        'X-Sanathan-Guest-Session': guestSessionId,
    };
  }
}
