import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/kos.dart';
import '../models/user.dart';

class ApiService {
  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach auth token if present
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // Helper method to get token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Auth
  Future<(User user, String token)> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data['data'];
      final token = (data?['token'] ?? '').toString();
      final userJson = data?['user'] as Map<String, dynamic>?;
      if (token.isNotEmpty && userJson != null) {
        final user = User.fromJson(userJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return (user, token);
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Login gagal',
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  Future<User> getProfile() async {
    final response = await _dio.get('/auth/user');
    final data = response.data['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<(User user, String token)> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String role, // 'owner' atau 'society'
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'role': role,
      },
    );

    if ((response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300) {
      final data = response.data['data'];
      final token = (data?['token'] ?? '').toString();
      final userJson = data?['user'] as Map<String, dynamic>?;
      if (token.isNotEmpty && userJson != null) {
        final user = User.fromJson(userJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return (user, token);
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Registrasi gagal',
    );
  }

  // Kos list (public)
  Future<List<Kos>> getKosList({
    int page = 1,
    String gender = 'all',
    String? search,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
  }) async {
    final qp = {
      'page': page,
      if (gender.isNotEmpty) 'gender': gender,
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
    };
    final response = await _dio.get('/kos', queryParameters: qp);
    // Laravel paginator: { success, data: { current_page, data: [ ... ] } }
    final payload = response.data['data'];
    final List items = (payload is Map && payload['data'] is List)
        ? payload['data']
        : (response.data['data'] as List? ?? const []);

    // Map loosely to our Kos model; fill image using first images[].file when exists
    return items.map<Kos>((raw) {
      final map = raw as Map<String, dynamic>;
      String? imageUrl;
      try {
        final images = map['images'] as List?;
        if (images != null && images.isNotEmpty) {
          final first = images.first as Map<String, dynamic>;
          final file = first['file']?.toString();
          if (file != null && file.isNotEmpty) {
            imageUrl = '$storageBaseUrl/$file';
          }
        }
      } catch (_) {}

      return Kos(
        id: (map['id'] as num).toInt(),
        name: (map['name'] ?? '').toString(),
        address: (map['address'] ?? '').toString(),
        description: (map['description'] as String?),
        image: imageUrl,
      );
    }).toList();
  }

  Future<({List<Kos> items, int? nextPage})> getKosPage({
    int page = 1,
    String gender = 'all',
    String? search,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
  }) async {
    final qp = {
      'page': page,
      if (gender.isNotEmpty) 'gender': gender,
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
    };
    final response = await _dio.get('/kos', queryParameters: qp);
    final payload = response.data['data'];
    final List itemsRaw = (payload is Map && payload['data'] is List)
        ? payload['data']
        : (response.data['data'] as List? ?? const []);
    final items = itemsRaw.map<Kos>((raw) {
      final map = raw as Map<String, dynamic>;
      String? imageUrl;
      try {
        final images = map['images'] as List?;
        if (images != null && images.isNotEmpty) {
          final first = images.first as Map<String, dynamic>;
          final file = first['file']?.toString();
          if (file != null && file.isNotEmpty) {
            imageUrl = '$storageBaseUrl/$file';
          }
        }
      } catch (_) {}
      return Kos(
        id: (map['id'] as num).toInt(),
        name: (map['name'] ?? '').toString(),
        address: (map['address'] ?? '').toString(),
        description: (map['description'] as String?),
        image: imageUrl,
      );
    }).toList();
    int? nextPage;
    if (payload is Map) {
      final current = payload['current_page'] as int?;
      final last = payload['last_page'] as int?;
      if (current != null && last != null && current < last) {
        nextPage = current + 1;
      }
    }
    return (items: items, nextPage: nextPage);
  }

  // Kos detail (public)
  Future<Map<String, dynamic>> getKosDetail(int id) async {
    final response = await _dio.get('/kos/$id');
    final data = response.data['data'];
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Gagal memuat detail kos',
    );
  }

  // Profile
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    final formData = FormData();
    if (name != null) formData.fields.add(MapEntry('name', name));
    if (phone != null) formData.fields.add(MapEntry('phone', phone));
    if (avatarPath != null && avatarPath.isNotEmpty) {
      formData.files.add(
        MapEntry('avatar', await MultipartFile.fromFile(avatarPath)),
      );
    }
    final response = await _dio.post(
      '/auth/profile',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _dio.post(
      '/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );

    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Gagal mengubah password',
      );
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      print('🔍 Checking email: $email');
      print('🌐 API Base URL: $apiBaseUrl');

      final response = await _dio.post(
        '/auth/check-email',
        data: {'email': email},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final success = data['success'] == true;
        print('✅ Email exists: $success');
        return success;
      }

      print('❌ Non-200 status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('💥 Error checking email: $e');
      if (e is DioException && e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        print('📡 Error response status: $statusCode');
        print('📄 Error response data: $responseData');

        // If status is 200 but success is false, email doesn't exist
        if (statusCode == 200 && responseData is Map) {
          return responseData['success'] == true;
        }
      }

      // For other errors, assume email doesn't exist
      print('❌ Assuming email doesn\'t exist due to error');
      return false;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _dio.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == false) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: data['message'] ?? 'Gagal mengubah password',
        );
      }
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Gagal mengubah password',
      );
    }
  }

  // Booking (requires auth: society)
  Future<Map<String, dynamic>> createBooking({
    required int kosId,
    required int roomId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Check if user is logged in
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/bookings'),
        message: 'Silakan login terlebih dahulu',
      );
    }

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      final response = await _dio.post(
        '/bookings',
        data: {
          'kos_id': kosId,
          'room_id': roomId,
          'start_date': fmt(startDate),
          'end_date': fmt(endDate),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final data = response.data['data'] ?? response.data;
        return (data is Map<String, dynamic>) ? data : {'data': data};
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data?['message'] ?? 'Gagal membuat booking',
      );
    } on DioException catch (e) {
      // Re-throw with better error message
      if (e.response?.statusCode == 403) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message:
              e.response?.data?['message'] ??
              'Akses ditolak. Pastikan Anda memiliki akses untuk melakukan booking.',
        );
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    // Cek role user untuk menentukan endpoint yang tepat
    User? user;
    try {
      print('DEBUG ApiService: Getting user profile to check role...');
      user = await getProfile();
      print(
        'DEBUG ApiService: User profile loaded - Role: ${user.role}, ID: ${user.id}, Email: ${user.email}',
      );
    } catch (e) {
      print('DEBUG ApiService: Failed to get profile: $e');
      // Jika getProfile gagal, kita akan coba kedua endpoint
    }

    // Jika user adalah owner, gunakan endpoint owner
    if (user?.role == 'owner') {
      try {
        print('DEBUG ApiService: Fetching owner bookings...');
        print(
          'DEBUG ApiService: User role: ${user?.role}, User ID: ${user?.id}',
        );
        final response = await _dio.get('/owner/bookings');
        print('DEBUG ApiService: Response status: ${response.statusCode}');
        print('DEBUG ApiService: Response headers: ${response.headers}');
        print(
          'DEBUG ApiService: Response data type: ${response.data.runtimeType}',
        );
        print(
          'DEBUG ApiService: Response data length: ${response.data is String ? (response.data as String).length : 'N/A'}',
        );
        print('DEBUG ApiService: Full response: ${response.data}');

        if (response.statusCode == 200) {
          // Handle both Map and String response
          Map<String, dynamic> responseData;

          if (response.data is Map) {
            responseData = response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            print('DEBUG ApiService: Response is String, parsing JSON...');
            try {
              responseData = (response.data as String).isNotEmpty
                  ? (jsonDecode(response.data as String)
                        as Map<String, dynamic>)
                  : <String, dynamic>{};
              print('DEBUG ApiService: Parsed JSON successfully');
            } catch (e) {
              print('DEBUG ApiService: Failed to parse JSON: $e');
              print('DEBUG ApiService: Raw response string: ${response.data}');
              return const [];
            }
          } else {
            print(
              'DEBUG ApiService: Unexpected response type: ${response.data.runtimeType}',
            );
            return const [];
          }

          print('DEBUG ApiService: Response keys: ${responseData.keys}');

          final data = responseData['data'];
          final debug = responseData['debug'];

          print('DEBUG ApiService: Data type: ${data.runtimeType}');
          print('DEBUG ApiService: Data value: $data');

          if (debug != null) {
            print('DEBUG ApiService: Debug info: $debug');
          }

          if (data is List) {
            print('DEBUG ApiService: Found ${data.length} bookings');
            if (data.isNotEmpty) {
              print('DEBUG ApiService: First booking: ${data.first}');
              print(
                'DEBUG ApiService: First booking keys: ${(data.first as Map).keys}',
              );
            } else if (debug != null) {
              print(
                'DEBUG ApiService: No bookings found. Owner has ${debug['kos_count']} kos',
              );
            }
            return data.cast<Map<String, dynamic>>();
          } else {
            print('DEBUG ApiService: Data is not a List! Data: $data');
          }
        } else {
          print(
            'DEBUG ApiService: Response status is not 200! Status: ${response.statusCode}',
          );
        }
        print('DEBUG ApiService: Returning empty list');
        return const [];
      } catch (e) {
        print('DEBUG ApiService: Error fetching owner bookings: $e');
        // Jika endpoint owner gagal, throw error dengan detail
        if (e is DioException) {
          print(
            'DEBUG ApiService: DioException - Status: ${e.response?.statusCode}, Message: ${e.response?.data}',
          );
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            message: e.message ?? 'Gagal memuat bookings owner',
          );
        }
        rethrow;
      }
    }

    // Jika user adalah society atau role tidak diketahui, coba endpoint society
    try {
      final response = await _dio.get('/bookings');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return const [];
    } catch (e) {
      // Jika endpoint society gagal dan role tidak diketahui, coba endpoint owner sebagai fallback
      if (user?.role == null &&
          e is DioException &&
          e.response?.statusCode == 403) {
        try {
          final ownerResponse = await _dio.get('/owner/bookings');
          if (ownerResponse.statusCode == 200 && ownerResponse.data is Map) {
            final ownerData = ownerResponse.data['data'];
            if (ownerData is List) {
              return ownerData.cast<Map<String, dynamic>>();
            }
          }
          return const [];
        } catch (ownerError) {
          // Jika kedua endpoint gagal, throw error asli dari society endpoint
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    // Check user role to determine endpoint
    User? user;
    try {
      user = await getProfile();
      print(
        'DEBUG ApiService: getBookingDetail - User role: ${user.role}, ID: ${user.id}',
      );
    } catch (e) {
      print('DEBUG ApiService: getBookingDetail - Failed to get profile: $e');
      // If getProfile fails, try default endpoint
    }

    // If user is owner, use owner endpoint
    if (user?.role == 'owner') {
      try {
        print(
          'DEBUG ApiService: getBookingDetail - Using owner endpoint for booking ID: $bookingId',
        );
        final response = await _dio.get('/owner/bookings/$bookingId');
        print(
          'DEBUG ApiService: getBookingDetail - Response status: ${response.statusCode}',
        );
        print(
          'DEBUG ApiService: getBookingDetail - Response data type: ${response.data.runtimeType}',
        );

        if (response.statusCode == 200) {
          // Handle both Map and String response
          Map<String, dynamic> responseData;

          if (response.data is Map) {
            responseData = response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            print(
              'DEBUG ApiService: getBookingDetail - Response is String, parsing JSON...',
            );
            try {
              responseData = (response.data as String).isNotEmpty
                  ? (jsonDecode(response.data as String)
                        as Map<String, dynamic>)
                  : <String, dynamic>{};
              print(
                'DEBUG ApiService: getBookingDetail - Parsed JSON successfully',
              );
            } catch (e) {
              print(
                'DEBUG ApiService: getBookingDetail - Failed to parse JSON: $e',
              );
              throw DioException(
                requestOptions: response.requestOptions,
                response: response,
                message: 'Gagal memparse response detail booking',
              );
            }
          } else {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              message: 'Format response tidak valid',
            );
          }

          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            print(
              'DEBUG ApiService: getBookingDetail - Successfully retrieved booking detail',
            );
            return data;
          } else {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              message: 'Data booking tidak ditemukan',
            );
          }
        }
      } catch (e) {
        print(
          'DEBUG ApiService: getBookingDetail - Error from owner endpoint: $e',
        );
        if (e is DioException) {
          print(
            'DEBUG ApiService: getBookingDetail - DioException status: ${e.response?.statusCode}',
          );
          print(
            'DEBUG ApiService: getBookingDetail - DioException data: ${e.response?.data}',
          );
        }
        // Don't fallback to society endpoint for owner - throw the error
        rethrow;
      }
    }

    // Default to society endpoint for society users
    try {
      print(
        'DEBUG ApiService: getBookingDetail - Using society endpoint for booking ID: $bookingId',
      );
      final response = await _dio.get('/bookings/$bookingId');
      if (response.statusCode == 200 && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          print(
            'DEBUG ApiService: getBookingDetail - Successfully retrieved booking detail from society endpoint',
          );
          return data;
        }
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Gagal memuat detail booking',
      );
    } catch (e) {
      print(
        'DEBUG ApiService: getBookingDetail - Error from society endpoint: $e',
      );
      rethrow;
    }
  }

  // Update booking status (Owner only)
  Future<Map<String, dynamic>> updateBookingStatus(
    int bookingId,
    String status, {
    String? rejectedReason,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (rejectedReason != null && rejectedReason.isNotEmpty) {
      data['rejected_reason'] = rejectedReason;
    }

    final response = await _dio.put(
      '/owner/bookings/$bookingId/status',
      data: data,
    );

    if (response.statusCode == 200 && response.data is Map) {
      return response.data as Map<String, dynamic>;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Gagal mengupdate status booking',
    );
  }

  // Kos Management (Owner)
  Future<Map<String, dynamic>> createKos({
    required String name,
    required String address,
    required String description,
    required String gender,
    required List<String> facilities,
    required List<String> paymentMethods,
    required List<Map<String, dynamic>> rooms,
    List<String>? images,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      // Step 1: Create basic kos
      final response = await _dio.post(
        '/owner/kos',
        data: {
          'name': name,
          'address': address,
          'description': description,
          'gender': gender == 'mixed'
              ? 'all'
              : gender, // Backend expects 'all' not 'mixed'
          'price_per_month': rooms.isNotEmpty
              ? (rooms.first['price'] as num?)?.toInt() ?? 0
              : 0,
          'whatsapp_number': '081234567890', // Default value
          'latitude': '-7.98390000', // Default value
          'longitude': '112.62140000', // Default value
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Create Kos Response: ${response.data}');

      // Get the created kos ID
      final kosId = response.data['data']['id'];

      // Step 2: Add rooms if any
      if (rooms.isNotEmpty) {
        await _dio.post(
          '/owner/kos/$kosId/rooms',
          data: {
            'rooms': rooms
                .map(
                  (room) => {
                    'room_number': room['room_number'] ?? room['name'] ?? 'A1',
                    'room_type':
                        room['room_type'] ??
                        'single', // Use room_type from form or default to single
                    'is_available': true,
                  },
                )
                .toList(),
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      // Step 3: Add facilities if any
      if (facilities.isNotEmpty) {
        await _dio.post(
          '/owner/kos/$kosId/facilities',
          data: {
            'facilities': facilities
                .map(
                  (facility) => {
                    'facility': facility,
                    'icon': _getFacilityIcon(facility),
                  },
                )
                .toList(),
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      // Step 4: Add payment methods if any
      if (paymentMethods.isNotEmpty) {
        await _dio.post(
          '/owner/kos/$kosId/payment-methods',
          data: {
            'payment_methods': paymentMethods
                .map(
                  (method) => {
                    'bank_name': 'BCA', // Default bank
                    'account_number': '1234567890', // Default account
                    'account_name': 'Gajayana Kost', // Default name
                    'type': _getPaymentType(method),
                  },
                )
                .toList(),
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      // Step 5: Upload images if any
      if (images != null && images.isNotEmpty) {
        final formData = FormData();

        // Add each image file to FormData
        // Laravel expects 'images' as array, use 'images[]' for each file
        for (int i = 0; i < images.length; i++) {
          final imagePath = images[i];
          if (imagePath.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'images[]', // Laravel will parse this as images array
                await MultipartFile.fromFile(imagePath),
              ),
            );
          }
        }

        // Set first image as primary (index 0)
        formData.fields.add(MapEntry('is_primary', '0'));

        try {
          final imageResponse = await _dio.post(
            '/owner/kos/$kosId/images',
            data: formData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

          print(
            'Images uploaded successfully for kos $kosId: ${imageResponse.data}',
          );
        } catch (e) {
          print('Error uploading images: $e');
          // Don't rethrow - kos is already created, images are optional
          // But log the error for debugging
          if (e is DioException) {
            print('DioException details: ${e.response?.data}');
          }
        }
      }

      return response.data;
    } catch (e) {
      print('Create Kos Error: $e');
      rethrow;
    }
  }

  String _getFacilityIcon(String facility) {
    switch (facility) {
      case 'AC':
        return 'ac';
      case 'Kamar Mandi Dalam':
        return 'bathroom';
      case 'Kamar Mandi Luar':
        return 'bathroom';
      case 'Laundry':
        return 'laundry';
      case 'TV':
        return 'tv';
      case 'Wifi':
        return 'wifi';
      case 'Parkir Motor':
        return 'parking';
      case 'Parkir Mobil':
        return 'parking';
      default:
        return 'default';
    }
  }

  String _getPaymentType(String method) {
    switch (method) {
      case 'Transfer Bank':
        return 'Transfer';
      case 'E-Wallet':
        return 'QRIS'; // E-Wallet biasanya menggunakan QRIS
      case 'Cash':
        return 'Cash';
      case 'Credit Card':
        return 'Transfer'; // Credit Card dianggap sebagai Transfer
      default:
        return 'Transfer';
    }
  }

  Future<Map<String, dynamic>> updateKos({
    required int id,
    required String name,
    required String address,
    required String description,
    required String gender,
    required List<String> facilities,
    required List<String> paymentMethods,
    required List<Map<String, dynamic>> rooms,
    List<String>? images,
  }) async {
    final response = await _dio.put(
      '/kos/$id',
      data: {
        'name': name,
        'address': address,
        'description': description,
        'gender': gender,
        'facilities': facilities,
        'payment_methods': paymentMethods,
        'rooms': rooms,
        'images': images ?? [],
      },
    );
    return response.data;
  }

  Future<void> deleteKos(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    await _dio.delete(
      '/owner/kos/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Review Management (Owner)
  Future<List<Map<String, dynamic>>> getOwnerReviews() async {
    try {
      final response = await _dio.get('/owner/reviews');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return const [];
    } catch (e) {
      print('Error fetching owner reviews: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> replyToReview(
    int reviewId,
    String ownerReply,
  ) async {
    try {
      final response = await _dio.post(
        '/owner/reviews/$reviewId/reply',
        data: {'owner_reply': ownerReply},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Gagal mengirim reply',
      );
    } catch (e) {
      print('Error replying to review: $e');
      rethrow;
    }
  }

  Future<List<Kos>> getMyKos() async {
    try {
      // Use the existing /kos endpoint and filter on frontend
      // This is simpler than creating a new backend endpoint
      final response = await _dio.get('/kos');
      final data = response.data['data'];

      if (data is Map && data['data'] is List) {
        final List<dynamic> kosList = data['data'];

        // For demo purposes, return all kos
        // In a real app, you could filter by user_id if needed
        return kosList.map((json) {
          final map = json as Map<String, dynamic>;
          String? imageUrl;
          try {
            final images = map['images'] as List?;
            if (images != null && images.isNotEmpty) {
              final first = images.first as Map<String, dynamic>;
              final file = first['file']?.toString();
              if (file != null && file.isNotEmpty) {
                imageUrl = '$storageBaseUrl/$file';
              }
            }
          } catch (_) {}

          return Kos(
            id: (map['id'] as num).toInt(),
            name: (map['name'] ?? '').toString(),
            address: (map['address'] ?? '').toString(),
            description: (map['description'] as String?),
            image: imageUrl,
            price: (map['price_per_month'] as num?)?.toDouble(),
            gender: (map['gender'] as String?),
            facilities: (map['facilities'] as List?)?.cast<String>() ?? [],
            paymentMethods: [], // Default empty for now
            rooms: [], // Default empty for now
          );
        }).toList();
      }

      return [];
    } catch (e) {
      // If there's an error, return empty list
      return [];
    }
  }
}
