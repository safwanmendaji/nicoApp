import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nicoapp/Model/general_followUp.dart';
import 'package:nicoapp/services/notication_services.dart';
import 'dart:convert';
import 'package:nicoapp/url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/services/firebase_api_service.dart';

class ApiService {
  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('${Url.baseUrl}${Url.login}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> signup(String email, String password) async {
    return await http.post(
      Uri.parse('${Url.baseUrl}${Url.signup}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<List<GeneralFollowUp>> fetchFollowUps(
      int page, int size) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      throw Exception('User not authenticated');
    }

    String dueDate() {
      DateTime now = DateTime.now();
      return DateFormat('yyyy-MM-dd').format(now);
    }

    final response = await http.get(
      Uri.parse(
          '${Url.baseUrl}generalFollowUp/getall?userId=$userId&page=$page&size=$size&dueDate=${dueDate()}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List followUps = data['data']['list'];
      print('====>>>> ${followUps}');

      print(
          '====>>>> ${followUps.map((json) => GeneralFollowUp.fromJson(json)).toList()}');
      return followUps.map((json) => GeneralFollowUp.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load follow-ups');
    }
  }

  static Future<Map<String, dynamic>> fetchDashboardData(
      String userId, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('${Url.baseUrl}user/dashboard/data?userId=$userId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  static Future<Map<String, dynamic>> fetchRoles({
    required int page,
    required int size,
    String? searchQuery, // Optional search query
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      // Construct the query parameters for page, size, and optional search
      String apiUrl = '${Url.baseUrl}roles/list?page=$page&size=$size';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        apiUrl += '&search=$searchQuery'; // Add search query if provided
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Return a map that contains roles and pagination info
        return {
          'roles': data['data']['roles'], // List of roles
          'totalItems': data['data']['totalItems'], // Total number of roles
          'totalPages': data['data']['totalPages'], // Total number of pages
          'currentPage': data['data']['currentPage'], // Current page
        };
      } else {
        throw Exception('Failed to load roles');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  static Future<http.Response> addUser({
    required String name,
    required String email,
    required String password,
    required String designation,
    required String mobileNo,
    required int roleId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('${Url.baseUrl}user/signup'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "designation": designation,
          "mobileNo": mobileNo,
          "role": {
            "id": roleId.toString(),
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception('Failed to add user');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  static Future<http.Response> createConsultant({
    required String consultantName,
    required String contactPerson,
    required String contactNumber,
    required int createdBy,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('${Url.baseUrl}consultant/save'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "consultantName": consultantName,
          "contactPerson": contactPerson,
          "contactNumber": contactNumber,
          "createdBy": {"id": createdBy}
        }),
      );

      return response;
    } else {
      throw Exception('User not authenticated');
    }
  }

  static Future<http.Response> searchConsultants(
      {required String query}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('${Url.baseUrl}consultant/all?search=$query&page=1&size=5'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      return response;
    } else {
      throw Exception('User not authenticated');
    }
  }

  static Future<http.Response> createConsumer({
    required String consumerName,
    required String emailId,
    required String address,
    required String contact,
    required int createdBy,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('${Url.baseUrl}consumer/save'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "consumerName": consumerName,
          "emailId": emailId,
          "address": address,
          "contact": contact,
          "createdBy": {"id": createdBy}
        }),
      );

      return response;
    } else {
      throw Exception('User not authenticated');
    }
  }

  static Future<Map<String, dynamic>> fetchUsers(
    int page,
    int size,
    String searchQuery,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse(
          '${Url.baseUrl}user/list?page=$page&size=$size&search=$searchQuery'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'list': data['data']['list'],
        'totalRecords': data['data']['totalRecords'],
        'currentPage': page,
      };
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<Map<String, dynamic>> fetchConsultants(
      int page, int size, String searchQuery) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url =
        '${Url.baseUrl}consultant/all?search=$searchQuery&page=$page&size=$size';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Return the required fields from the response
      return {
        'Consultants': data['data']?['Consultants'] ?? [],
        'totalRecords': data['data']?['totalRecords'] ?? 0,
      };
    } else {
      throw Exception('Failed to load consultants');
    }
  }

  static Future<Map<String, dynamic>> fetchConsumers(
      int page, int size, String searchQuery) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url =
        '${Url.baseUrl}consumer/all?search=$searchQuery&page=$page&size=$size';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Assuming the response contains totalRecords and a list of consumsers
      return {
        'consumers': data['data']?['consumers'] ?? [],
        'totalRecords': data['data']?['totalRecords'] ?? 0,
      };
    } else {
      throw Exception('Failed to load consumers');
    }
  }

  static Future<Map<String, dynamic>> fetchGeneralFollowUps(
      int page, int size, String userId, String searchQuery) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse(
          '${Url.baseUrl}generalFollowUp/getall?userId=$userId&page=$page&size=$size'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'list': data['data']['list'],
        'totalRecords': data['data']['totalRecords'],
        'totalPages': data['data']['totalPages'],
      };
    } else {
      throw Exception('Failed to load general follow-ups');
    }
  }

  /// Example of sending Firebase Token to the backend
  void sendFirebaseToken(String token, String deviceId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId != null) {
        final response =
            await FirebaseApiService.requestTokenToSendNotification(
          userId: userId,
          flutterToken: token,
          deviceId: deviceId,
        );

        if (response.statusCode == 200) {
          print('Firebase token sent successfully');
        } else {
          print('Failed to send token: ${response.statusCode}');
        }
      } else {
        print('User ID not found in local storage');
      }
    } catch (e) {
      print('Error sending token: $e');
    }
  }

// Example of sending a push notification
  void sendPushNotification(String title, String message, String token) async {
    try {
      final response = await FirebaseApiService.sendTokenNotification(
        title: title,
        message: message,
        token: token,
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<http.Response> saveGeneralFollowUp(
    String generalFollowUpName,
    int followUpPersonId,
    String description,
    String status,
    String statusNotes,
    String dueDate, // Expect dueDate as a string in 'yyyy-MM-dd HH:mm' format
  ) async {
    try {
      // Retrieve token and userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? userIdString = prefs.getString('userId');
      int? userId = int.tryParse(userIdString ?? '');

      // Check if userId and token are valid
      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      // Construct the request payload
      Map<String, dynamic> requestBody = {
        "generalFollowUpName": generalFollowUpName,
        "followUpPerson": {"id": followUpPersonId}, // Updated
        "description": description,
        "status": status,
        "statusNotes": statusNotes,
        "dueDate": dueDate, // Pass due date as a string with date and time
        "createdBy": {"id": userId} // Pass the userId for createdBy
      };

      // Make the POST request
      http.Response response = await http.post(
        Uri.parse('${Url.baseUrl}generalFollowUp/save'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      // Return the response
      return response;
    } catch (e) {
      throw Exception('Error saving General Follow-Up: $e');
    }
  }

  static Future<http.Response> saveInquiry({
    required String projectName,
    required String inquiryStatus,
    required int consumerId,
    required int productId,
    required int consultantId,
    required String remark,
    required String createdAt,
    required int createdBy,
    required int followUpUser,
    required int followUpQuotation,
    required String description,
    required int brandId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Build the request body with brandId included
    final body = jsonEncode({
      "projectName": projectName,
      "inquiryStatus": inquiryStatus,
      "consumerId": consumerId,
      "productId": productId,
      "consultantId": consultantId,
      "remark": remark,
      "createdBy": createdBy,
      "followUpUser": followUpUser,
      "followUpQuotation": followUpQuotation,
      "description": description,
      "brandId": brandId, // Include the brandId in the request
    });

    // Send POST request to the API
    final response = await http.post(
      Uri.parse('${Url.baseUrl}inquiry/save'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    // Return the response
    return response;
  }

  static Future<Map<String, dynamic>> saveBrand(String brandName) async {
    try {
      // Retrieve token and userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? userIdString = prefs.getString('userId');
      int? userId = int.tryParse(userIdString ?? '');

      // Check if userId and token are valid
      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      // Construct the API URL
      final url = Uri.parse('${Url.baseUrl}brand/save?userId=$userId');

      // Make the POST request
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "brandName": brandName,
        }),
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the decoded response
      } else {
        throw Exception(
            'Failed to save brand. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving brand: $e');
    }
  }

  // // Function to fetch the list of brands
  // static Future<Map<String, dynamic>> fetchBrands(
  //     int page, int size, String searchQuery,
  //     {String search = ''}) async {
  //   try {
  //     // Retrieve the token from SharedPreferences
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? token = prefs.getString('auth_token');

  //     if (token == null) {
  //       throw Exception('User not authenticated');
  //     }

  //     // Construct the API URL
  //     final url = Uri.parse(
  //         '${Url.baseUrl}brand/list?search=$search&page=$page&size=$size');

  //     // Make the GET request
  //     final response = await http.get(
  //       url,
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $token",
  //       },
  //     );

  //     // Check if the response is successful
  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body); // Return the decoded response
  //     } else {
  //       throw Exception(
  //           'Failed to fetch brands. Status Code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching brands: $e');
  //   }
  // }

  // static Future<List<dynamic>> fetchProductsByBrands(List<int> brandIds,
  //     {int page = 1, int size = 10}) async {
  //   try {
  //     // Retrieve token from SharedPreferences
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? token = prefs.getString('auth_token');

  //     // Ensure the token is available
  //     if (token == null) {
  //       throw Exception('Authorization token not found');
  //     }

  //     // Construct the API URL with the brandIds, page, and size
  //     String brandIdsString =
  //         brandIds.join(','); // Convert list to comma-separated string
  //     final Uri url = Uri.parse(
  //         '${Url.baseUrl}product/listByBrands?brandIds=$brandIdsString&page=$page&size=$size');

  //     // Make the GET request
  //     final response = await http.get(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $token', // Add token to the request header
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     // Check if the response is successful
  //     if (response.statusCode == 200) {
  //       // Decode the response JSON
  //       final data = json.decode(response.body);

  //       // Ensure the 'data' key exists and is a list of products
  //       if (data['data'] != null && data['data'] is List) {
  //         return data['data']; // Return the list of products
  //       } else {
  //         throw Exception('No products found');
  //       }
  //     } else {
  //       throw Exception(
  //           'Failed to fetch products. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching products by brands: $e');
  //   }
  // }

// Method to fetch the list of brands
  static Future<Map<String, dynamic>> fetchBrands(
      int page, int size, String searchQuery) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    // API call for fetching brands
    final Uri url = Uri.parse(
        '${Url.baseUrl}brand/list?search=$searchQuery&page=$page&size=$size');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch brands. Status code: ${response.statusCode}');
    }
  }

  // Method to create a product
  static Future<Map<String, dynamic>> createProduct({
    required String productName,
    required double price,
    required int brandId,
    required int createdById,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    if (authToken == null) {
      throw Exception('Authorization token not found');
    }

    final url = Uri.parse('${Url.baseUrl}product/create');

    final Map<String, dynamic> requestBody = {
      'productName': productName,
      'price': price,
      'brand': {
        'brandId': brandId,
      },
      'createdBy': {
        'id': createdById,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'status': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'status': false,
          'message': 'Failed to create product: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchProducts(
      int page, int size, String searchQuery, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('userId'); // Fetch userId

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    // API call for fetching products with pagination
    final Uri url = Uri.parse(
        '${Url.baseUrl}product/list?search=$searchQuery&page=$page&size=$size&userId=$userId'); // Include userId
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['data'] != null && data['data']['productList'] != null) {
        return {
          'totalRecords': data['data']['totalRecords'], // Check the casing here
          'totalPages': data['data']['totalPages'], // Check the casing here
          'productList': data['data']['productList'],
        };
      } else {
        throw Exception('Invalid data format received');
      }
    } else {
      throw Exception(
          'Failed to fetch products. Status code: ${response.statusCode}');
    }
  }

  // Method to fetch inquiries based on userId
  static Future<Map<String, dynamic>> fetchInquiries(
      int page, int size, String searchQuery, String inquiryStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('userId');

    if (token == null) {
      throw Exception('Authorization token not found');
    }

    if (userId == null) {
      throw Exception('User ID not found in local storage');
    }

    // API call for fetching inquiries
    final Uri url = Uri.parse(
        '${Url.baseUrl}inquiry/all?search=$searchQuery&page=$page&size=$size&userId=$userId&inquiry-status=$inquiryStatus');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Check if the data structure is correct and extract necessary info
      if (data['data'] != null && data['data']['inquiries'] != null) {
        return {
          'totalRecords': data['data']['inquiries']['totalElements'],
          'totalPages': data['data']['inquiries']['totalPages'],
          'inquiryList': data['data']['inquiries']['content'],
        };
      } else {
        throw Exception('Invalid data format received');
      }
    } else {
      throw Exception(
          'Failed to fetch inquiries. Status code: ${response.statusCode}');
    }
  }

  // Save role function
  static Future<http.Response> saveRole({required String roleName}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('${Url.baseUrl}roles/save'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "roleName": roleName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception('Failed to save role');
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

// Assuming getGeneralFollowUpById is an instance method
  Future<Map<String, dynamic>> getGeneralFollowUpById(
      int generalFollowUpId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token not found.');
    }

    final response = await http.get(
      Uri.parse('${Url.baseUrl}generalFollowUp/get/$generalFollowUpId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Parse the JSON response
    } else if (response.statusCode == 404) {
      throw Exception('General Follow-Up not found.');
    } else {
      throw Exception('Failed to load General Follow-Up.');
    }
  }

  static Future<void> updateGeneralFollowUp(
    int generalFollowUpId,
    String generalFollowUpName,
    int followUpPersonId,
    String description,
    String status,
    String statusNotes,
    String dueDate,
  ) async {
    // Fetch token and updatedById from local storage (SharedPreferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? updatedById = prefs.getString('userId');

    // Error handling for missing token or updatedById
    if (token == null || updatedById == null) {
      throw Exception('Token or updatedById not found in local storage.');
    }

    // Construct the API endpoint
    final url =
        Uri.parse('${Url.baseUrl}generalFollowUp/update/$generalFollowUpId');

    // Prepare the request body as a JSON object
    final body = jsonEncode({
      "generalFollowUpName": generalFollowUpName,
      "followUpPerson": {"id": followUpPersonId},
      "description": description,
      "status": status,
      "statusNotes": statusNotes,
      "dueDate": dueDate, // Ensure the date is in ISO format
      "updatedBy": {"id": updatedById}
    });

    // Make the PUT request to the API
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Handle the response status
    if (response.statusCode == 200) {
      print('GeneralFollowUp updated successfully');
    } else {
      // Provide more detailed error messages based on status code
      throw Exception(
          'Failed to update GeneralFollowUp. Status Code: ${response.statusCode}, Message: ${response.body}');
    }
  }

  static Future<void> updateUserStatus(int userId, bool isActive) async {
    // Get token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Make the PATCH request to update user status
      final response = await http.put(
        Uri.parse('${Url.baseUrl}user/active/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'active': isActive}), // Correct key 'active'
      );

      if (response.statusCode == 200) {
        // Parse the successful response body
        final responseBody = jsonDecode(response.body);
        print(
            responseBody['message']); // Expected response: "User is now active"

        // Optionally handle the 'data' field (e.g., updating user information)
        print("Updated user: ${responseBody['data']}");
      } else {
        // Handle the error response
        final errorResponse = jsonDecode(response.body);
        throw Exception('Failed to update status: ${errorResponse['message']}');
      }
    } catch (error) {
      // Handle any other errors
      throw Exception('Error updating user status: $error');
    }
  }

  static Future<void> deleteUser(String userId, String token) async {
    final response = await http.delete(
      Uri.parse(
          '${Url.baseUrl}user/delete/$userId'), // Ensure this is your API endpoint
      headers: {
        'Authorization': 'Bearer $token', // Ensure the token is correctly added
        'Content-Type': 'application/json',
      },
    );

    // Check the status code and throw an exception if it's not 200
    if (response.statusCode == 200) {
      print('User deleted successfully');
    } else {
      print(
          'Failed to delete user. Status code: ${response.statusCode}, Response: ${response.body}');
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  // Fetch user details by ID
  static Future<Map<String, dynamic>?> fetchUserById(int userId) async {
    final prefs = await SharedPreferences
        .getInstance(); // Get the SharedPreferences instance
    final authToken = prefs.getString('auth_token'); // Retrieve the auth token

    final response = await http.get(
      Uri.parse('${Url.baseUrl}user/get/$userId'),
      headers: {
        'Authorization':
            'Bearer $authToken', // Add the token to the request headers
        'Content-Type': 'application/json', // Specify content type if needed
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Check if the response contains the "data" field
      if (responseBody.containsKey('data')) {
        return responseBody['data']; // Return only the user data
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('Failed to load user details');
    }
  }

  static Future<bool> deleteConsultant(int consultantId) async {
    final url = Uri.parse('${Url.baseUrl}consultant/delete/$consultantId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken =
          prefs.getString('auth_token'); // Replace 'auth_token' with your key

      // Prepare headers
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the auth token to headers
        'Content-Type': 'application/json', // Optional: Add content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print(
            'Failed to delete consultant. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting consultant: $e');
      return false;
    }
  }

  static Future<bool> deleteInquiry(int inquiryId) async {
    // Construct the URL with the provided inquiry ID
    final url = Uri.parse('${Url.baseUrl}inquiry/delete/$inquiryId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(
          'auth_token'); // Make sure this key matches your saved token

      // Prepare headers with the authentication token
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the token here
        'Content-Type': 'application/json', // Optional: Specify content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print('Failed to delete inquiry. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting inquiry: $e');
      return false;
    }
  }

  static Future<bool> deleteConsumer(int consumerId) async {
    // Construct the URL with the provided inquiry ID
    final url = Uri.parse('${Url.baseUrl}consumer/delete/$consumerId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(
          'auth_token'); // Make sure this key matches your saved token

      // Prepare headers with the authentication token
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the token here
        'Content-Type': 'application/json', // Optional: Specify content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print('Failed to delete Consumer. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting consumer: $e');
      return false;
    }
  }

  static Future<bool> deleteGeneralFollowUp(int generalFollowUpId) async {
    // Construct the URL with the provided inquiry ID
    final url =
        Uri.parse('${Url.baseUrl}generalFollowUp/delete/$generalFollowUpId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(
          'auth_token'); // Make sure this key matches your saved token

      // Prepare headers with the authentication token
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the token here
        'Content-Type': 'application/json', // Optional: Specify content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print(
            'Failed to delete GeneralFollowUp. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting GeneralFollowUp: $e');
      return false;
    }
  }

  static Future<bool> deleteBrand(int brandId) async {
    // Construct the URL with the provided inquiry ID
    final url = Uri.parse('${Url.baseUrl}brand/delete/$brandId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(
          'auth_token'); // Make sure this key matches your saved token

      // Prepare headers with the authentication token
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the token here
        'Content-Type': 'application/json', // Optional: Specify content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print('Failed to delete Brand. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting Brand: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(int productId) async {
    // Construct the URL with the provided inquiry ID
    final url = Uri.parse('${Url.baseUrl}product/delete/$productId');

    try {
      // Retrieve the token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString(
          'auth_token'); // Make sure this key matches your saved token

      // Prepare headers with the authentication token
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken', // Add the token here
        'Content-Type': 'application/json', // Optional: Specify content type
      };

      // Make the DELETE request with headers
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print('Failed to delete Product. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting Product: $e');
      return false;
    }
  }

  static Future<bool> deleteRole(int roleId) async {
    final url = Uri.parse('${Url.baseUrl}roles/delete/$roleId');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        return true; // Successful deletion
      } else {
        print('Failed to delete Role. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting Role: $e');
      return false;
    }
  }

  static updateGeneralFollowUpName(int followUpId, String editedName) {}

  // Update user function for PUT request
  static Future<http.Response> updateUser({
    required int userId,
    required String name,
    required String email,
    required String designation,
    required String mobileNo,
    required int roleId,
  }) async {
    final String url = '${Url.baseUrl}user/editProfile';

    // Construct the body of the request
    final Map<String, dynamic> body = {
      'id': userId,
      'name': name,
      'email': email,
      'designation': designation,
      'mobileNo': mobileNo,
      'roleId': roleId,
    };

    try {
      // Retrieve the auth_token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      // Check if the token exists
      if (authToken == null || authToken.isEmpty) {
        throw Exception('No auth token found');
      }

      // Make the PUT request
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Attach the token
        },
        body: jsonEncode(body), // Encode body to JSON format
      );

      // Check for successful response (status code 200–299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        // If the server returns an error, throw an exception
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      // Catch any errors and rethrow them
      throw Exception('Error updating user: $e');
    }
  }

  // Fetch user details by ID
  static Future<Map<String, dynamic>?> fetchConsultantById(
      int consumerId) async {
    final prefs = await SharedPreferences
        .getInstance(); // Get the SharedPreferences instance
    final authToken = prefs.getString('auth_token'); // Retrieve the auth token

    final response = await http.get(
      Uri.parse('${Url.baseUrl}consultant/get/$consumerId'),
      headers: {
        'Authorization':
            'Bearer $authToken', // Add the token to the request headers
        'Content-Type': 'application/json', // Specify content type if needed
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Check if the response contains the "data" field
      if (responseBody.containsKey('data')) {
        return responseBody['data']; // Return only the user data
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('Failed to load user details');
    }
  }

  // Method to update a consultant
  static Future<http.Response> updateConsultant({
    required int consultantId,
    required String consultantName,
    required String contactPerson,
    required String contactNumber,
    required int updatedBy,
  }) async {
    final String url =
        '${Url.baseUrl}consultant/update/$consultantId'; // Endpoint for updating a consultant

    // Construct the body of the request
    final Map<String, dynamic> body = {
      'consultantName': consultantName,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'updatedBy': {
        'id': updatedBy, // updatedBy as an object with "id"
      },
    };

    // Get the auth token from local storage (if needed)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    try {
      // Make the PUT request to update the consultant
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json', // Set the content type
          'Authorization': 'Bearer $token', // Pass the auth token (if required)
        },
        body: jsonEncode(body), // Encode body to JSON format
      );

      return response; // Return the response from the API
    } catch (e) {
      // Handle errors and return an error response
      throw Exception('Error updating consultant: $e');
    }
  }

  // Fetch user details by ID
  static Future<Map<String, dynamic>?> fetchConsumerById(int consumerId) async {
    final prefs = await SharedPreferences
        .getInstance(); // Get the SharedPreferences instance
    final authToken = prefs.getString('auth_token'); // Retrieve the auth token

    final response = await http.get(
      Uri.parse('${Url.baseUrl}consumer/get/$consumerId'),
      headers: {
        'Authorization':
            'Bearer $authToken', // Add the token to the request headers
        'Content-Type': 'application/json', // Specify content type if needed
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Check if the response contains the "data" field
      if (responseBody.containsKey('data')) {
        return responseBody['data']; // Return only the user data
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('Failed to load user details');
    }
  }

  // Update consumer function
  static Future<http.Response> updateConsumer({
    required int consumerId,
    required String consumerName,
    required String emailId,
    required String address,
    required String contact,
    required int updatedBy,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Fetch auth token

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final String url =
        '${Url.baseUrl}consumer/update/$consumerId'; // Replace with your actual URL

    // Construct the request body
    final Map<String, dynamic> body = {
      "consumerName": consumerName,
      "emailId": emailId,
      "address": address,
      "contact": contact,
      "updatedBy": {
        "id": updatedBy,
      }
    };

    try {
      // Make the PUT request to update the consumer
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body), // Convert body to JSON
      );

      if (response.statusCode == 200) {
        print('Consumer updated successfully');
      } else {
        print('Failed to update consumer. Status code: ${response.statusCode}');
      }

      return response; // Return the response
    } catch (e) {
      throw Exception('Error updating consumer: $e');
    }
  }

  // Fetch user details by ID
  static Future<Map<String, dynamic>?> fetchBrandById(int brandId) async {
    final prefs = await SharedPreferences
        .getInstance(); // Get the SharedPreferences instance
    final authToken = prefs.getString('auth_token'); // Retrieve the auth token

    final response = await http.get(
      Uri.parse('${Url.baseUrl}brand/get/$brandId'),
      headers: {
        'Authorization':
            'Bearer $authToken', // Add the token to the request headers
        'Content-Type': 'application/json', // Specify content type if needed
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Check if the response contains the "data" field
      if (responseBody.containsKey('data')) {
        return responseBody['data']; // Return only the user data
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('Failed to load user details');
    }
  }

// Update brand function
  static Future<http.Response> updateBrand({
    required int brandId,
    required String brandName,
    required int updatedBy,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Fetch the auth token

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Construct the API URL, using the brandId and updatedBy
    final String url = '${Url.baseUrl}brand/edit/$brandId?userId=$updatedBy';

    // Construct the request body
    final Map<String, dynamic> body = {
      "brandName": brandName,
    };

    try {
      // Make the PUT request to update the brand
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Include the auth token
          'Content-Type': 'application/json', // Specify JSON content type
        },
        body: jsonEncode(body), // Convert the body to JSON
      );

      if (response.statusCode == 200) {
        print('Brand updated successfully');
      } else {
        print('Failed to update brand. Status code: ${response.statusCode}');
      }

      return response; // Return the response
    } catch (e) {
      throw Exception('Error updating brand: $e');
    }
  }

  // Fetch user details by ID
  static Future<Map<String, dynamic>?> fetchRoleById(int id) async {
    final prefs = await SharedPreferences
        .getInstance(); // Get the SharedPreferences instance
    final authToken = prefs.getString('auth_token'); // Retrieve the auth token

    final response = await http.get(
      Uri.parse('${Url.baseUrl}roles/get/$id'),
      headers: {
        'Authorization':
            'Bearer $authToken', // Add the token to the request headers
        'Content-Type': 'application/json', // Specify content type if needed
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // Check if the response contains the "data" field
      if (responseBody.containsKey('data')) {
        return responseBody['data']; // Return only the user data
      } else {
        throw Exception('User data not found');
      }
    } else {
      throw Exception('Failed to load user details');
    }
  }

  static Future<http.Response> updateRole({
    required int roleId,
    required String roleName,
    required int updatedBy,
  }) async {
    final String url = '${Url.baseUrl}roles/edit/$roleId';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Fetch the userId and token from local storage
      String? userId = prefs.getString('userId');
      String? token = prefs.getString('auth_token');

      if (userId == null || token == null) {
        throw Exception('User ID or authentication token not found.');
      }

      // Make the PUT request to update the role
      final response = await http.put(
        Uri.parse(
            '$url?userId=$userId'), // Append the userId as a query parameter
        headers: {
          'Authorization': 'Bearer $token', // Include the auth token in headers
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'roleName': roleName, // Only the role name is passed in the body
        }),
      );

      return response; // Return the response from the API
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  // Fetch inquiry by ID API
  static Future<Map<String, dynamic>?> fetchInquiryById(int inquiryId) async {
    try {
      // Retrieve auth token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // API URL for fetching inquiry by ID
      final String url = '${Url.baseUrl}inquiry/get/$inquiryId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Attach the Bearer token
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        // Check if the API response has a "data" field
        if (responseBody.containsKey('data')) {
          return responseBody['data']; // Return the data field
        } else {
          throw Exception('Inquiry data not found');
        }
      } else {
        throw Exception('Failed to load inquiry details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching inquiry: $e');
    }
  }

  // Update inquiry by ID API
  static Future<http.Response> updateInquiry({
    required int inquiryId,
    required String projectName,
    required String inquiryStatus,
    required int consumerId,
    required int productId,
    required int brandId,
    required int consultantId,
    required String remark,
    required int updatedBy,
    required int followUpUser,
    required int followUpQuotation,
    required String description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final String url = '${Url.baseUrl}inquiry/update/$inquiryId';

    return http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'projectName': projectName,
        'inquiryStatus': inquiryStatus,
        'consumerId': consumerId,
        'productId': productId,
        'brandId': brandId,
        'consultantId': consultantId,
        'remark': remark,
        'updatedBy': updatedBy,
        'followUpUser': followUpUser,
        'followUpQuotation': followUpQuotation,
        'description': description,
      }),
    );
  }

  // Fetch Product by ID
  static Future<Map<String, dynamic>> fetchProductById(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    final url = Uri.parse('${Url.baseUrl}product/get/$productId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': true,
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'status': false,
          'message': 'Failed to fetch product: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String productName,
    required double price,
    required int brandId,
    required int updatedById,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    final url = Uri.parse('${Url.baseUrl}product/update/$productId');

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'productName': productName,
      'price': price,
      'brand': {
        'brandId': brandId,
      },
      'updatedBy': {
        'id': updatedById,
      },
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'status': false,
          'message': 'Failed to update product: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'An error occurred: $e'};
    }
  }

  // Method to fetch calendar events based on month and userId
  static Future<List<dynamic>> fetchCalendarEvents(int month) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve auth_token and userId from local storage
    String? authToken = prefs.getString('auth_token');
    int? userId = prefs.getInt('userId');

    // Check if authToken and userId are available
    if (authToken == null || userId == null) {
      throw Exception('auth_token or userId is missing from local storage');
    }

    final String apiUrl =
        '${Url.baseUrl}dashboard/calenderevent?month=$month&userId=$userId';

    try {
      // Make the HTTP GET request with the auth token in the headers
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization':
              'Bearer $authToken', // Attach the auth_token in the Authorization header
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final jsonResponse = jsonDecode(response.body);

        // Ensure the structure of the response matches what you're expecting
        if (jsonResponse['data'] != null && jsonResponse['data'] is Map) {
          final data = jsonResponse['data'] as Map<String, dynamic>;

          // You can directly return the list of events in 'data'
          return data.values
              .expand((events) => events as List<dynamic>)
              .toList();
        } else {
          throw Exception('Invalid data structure in response');
        }
      } else {
        throw Exception(
            'Failed to load calendar events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching calendar events: $e');
    }
  }

  static Future<void> markFollowUpAsDone(
      int followUpId, int updatedById, String description) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    if (authToken == null) {
      throw Exception('Auth token is missing');
    }

    final String apiUrl = '${Url.baseUrl}generalFollowUp/make/done/$followUpId';

    final body = jsonEncode({
      "description": "Mark As Done",
      "updatedBy": {"id": updatedById},
      "status": "COMPLETED"
    });

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Follow-up marked as done successfully');
      } else {
        print(
            'Failed to mark follow-up as done. Status code: ${response.statusCode}');
        throw Exception('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to mark follow-up as done');
    }
  }

  // Method to mark inquiry quotation as done
  static Future<http.Response> markQuotationAsDone({
    required String followUpUser,
    required String userId, // Login User ID
    required String description,
    required bool isQuotationGiven,
    required int inquiryId, // Inquiry ID, e.g., 17 in your example
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token'); // Retrieve auth_token

    if (authToken == null) {
      throw Exception('Authentication token is missing');
    }

    final url = Uri.parse('${Url.baseUrl}inquiry/quotation/done/$inquiryId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken', // Attach auth_token here
    };

    final body = jsonEncode({
      "followUpUser": followUpUser,
      "userId": userId, // Login User ID
      "description": description,
      "isQuotationGiven": isQuotationGiven,
    });

    final response = await http.put(
      url,
      headers: headers,
      body: body,
    );

    return response;
  }

  static Future<http.Response> reassignQuotation({
    required int inquiryId,
    required int followUpUser,
    required int userId,
    required String description,
    required String authToken,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        throw Exception('Auth token is missing');
      }

      // Prepare the API URL and headers
      String url = '${Url.baseUrl}inquiry/quotation/reassing/$inquiryId';
      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

      // Prepare the request body
      Map<String, dynamic> body = {
        'userId': userId,
        'followUpQuotation': followUpUser,
        'description': description,
      };

      // Make the PUT request to reassign the quotation
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception('Failed to reassign quotation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during reassigning quotation: $e');
    }
  }

  static Future<http.Response> forgotPassword(String email) async {
    final String url = '${Url.baseUrl}user/forgotpassword';

    // Retrieve auth token from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Set up headers including the auth_token
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Body of the POST request
    final Map<String, String> body = {
      'email': email,
    };

    try {
      // Send POST request
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    } catch (e) {
      throw Exception('Failed to send password reset request: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchInquiriesForDashboard() async {
    final String baseUrl = '${Url.baseUrl}dashboard/getGFAndInq';

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdString = prefs.getString('userId');
      int? userId = userIdString != null ? int.tryParse(userIdString) : null;
      if (userId == null) throw Exception('User ID not found');

      final DateTime now = DateTime.now();
      String dueDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final Uri requestUrl =
          Uri.parse('$baseUrl?userId=$userId&dueDate=$dueDate');
      print("url===>>> + ${requestUrl}");
      String? authToken = prefs.getString('auth_token');
      if (authToken == null) throw Exception('Auth token not found');

      Map<String, String> headers = {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

      final response = await http.get(requestUrl, headers: headers);
      print("==== response =====>>>  + ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final Map<String, dynamic>? data = decodedResponse['data'];
        print("==== DATA=====>>>  + ${data}");
        if (data != null) {
          print('Data fetched successfully: $data');
          return data; // Return the whole data object
        } else {
          throw Exception('Data field is missing in the response');
        }
      } else {
        throw Exception('Failed to load inquiries: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching inquiries: $error');
      rethrow;
    }
  }

  // Method to send the device token to the server
  static Future<http.Response?> sendTokenToServer(
      String userId, String deviceToken) async {
    var uri = Uri.parse('${Url.baseUrl}notification/requesttoken?isWeb=false');

    try {
      // Get auth_token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        print('Auth token is missing');
        return null;
      }

      var response = await http.put(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $authToken', // Attach auth token
        },
        body: jsonEncode(<String, dynamic>{
          'userId': int.parse(userId), // Ensure userId is passed as an integer
          'deviceId': deviceToken, // Send the device token
        }),
      );

      return response;
    } catch (e) {
      print('Error sending token to server: $e');
      return null;
    }
  }

  // Method to get and use the device token
  void useDeviceToken() async {
    NotificationServices notificationServices = NotificationServices();
    String? deviceToken = await notificationServices.getDeviceToken();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId =
        prefs.getString('userId'); // Get userId from SharedPreferences

    if (deviceToken != null && userId != null) {
      print("Device Token: $deviceToken");
      // Pass the token and userId to your sendTokenToServer method
      await sendTokenToServer(userId, deviceToken);
    } else {
      if (deviceToken == null) {
        print("Failed to retrieve device token");
      }
      if (userId == null) {
        print("UserId is missing");
      }
    }
  }

  Future<List<String>?> fetchInquiryStatus() async {
    final url = Uri.parse('${Url.baseUrl}inquiry/inquirystatus');
    try {
      // Retrieve auth_token from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      // Add the token to the request headers
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return List<String>.from(jsonResponse['data']);
      } else {
        print('Failed to load inquiry statuses');
        return null;
      }
    } catch (error) {
      print('Error fetching inquiry status: $error');
      return null;
    }
  }

  // Future<Map<String, dynamic>?> fetchProductList(
  //   int currentPage, {
  //   String? search,
  //   required int page,
  //   required int size,
  //   required int userId,
  //   required int pageSize,
  // }) async {
  //   final url = Uri.parse(
  //       '${Url.baseUrl}product/list?search=$search&page=$page&size=$size&userId=$userId');

  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     String? authToken = prefs.getString('auth_token');

  //     final response = await http.get(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $authToken',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final jsonResponse = json.decode(response.body);
  //       return jsonResponse['data'];
  //     } else {
  //       print('Failed to load product list');
  //       return null;
  //     }
  //   } catch (error) {
  //     print('Error fetching product list: $error');
  //     return null;
  //   }
  // }

  Future<List<Map<String, dynamic>>?> fetchInquiriesByProduct(
      int productId) async {
    final url =
        Uri.parse('${Url.baseUrl}inquiry/getinquirybyproduct/$productId');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      } else {
        print('Failed to load inquiries for product $productId');
        return null;
      }
    } catch (error) {
      print('Error fetching inquiries for product: $error');
      return null;
    }
  }

  // Fetch inquiry statuses
  static Future<List<String>> fetchInquiryStatuses() async {
    final response =
        await http.get(Uri.parse('$Url.baseUrl/inquiry/inquirystatus'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Return the list of inquiry statuses from the response
      return List<String>.from(data['data']);
    } else {
      throw Exception('Failed to load inquiry statuses');
    }
  }

  static Future<List<dynamic>> fetchProductsByBrand(int brandId,
      {int page = 1, int size = 10}) async {
    try {
      // Retrieve token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      // Ensure the token is available
      if (token == null) {
        throw Exception('Authorization token not found');
      }

      // Construct the API URL with the brandId, page, and size
      final Uri url = Uri.parse(
          '${Url.baseUrl}product/listByBrand/$brandId?page=$page&size=$size');

      // Make the GET request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add token to the request header
          'Content-Type': 'application/json',
        },
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Decode the response JSON
        final data = json.decode(response.body);

        // Ensure the 'data' key exists and is a list of products
        if (data['data'] != null && data['data'] is List) {
          return data['data']; // Return the list of products
        } else {
          throw Exception('No products found');
        }
      } else {
        throw Exception(
            'Failed to fetch products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products by brand: $e');
    }
  }

  static Future<void> updateWinOrLossStatus(
    int inquiryId,
    int userId,
    bool isWin, // Add isWin parameter
  ) async {
    try {
      // Retrieve token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      // Ensure the token is available
      if (token == null) {
        throw Exception('Authorization token not found');
      }

      // Construct the API URL with the inquiryId, userId, and isWin
      final Uri url = Uri.parse(
        '${Url.baseUrl}inquiry/winorloss/$inquiryId?userId=$userId&isWin=$isWin', // Pass isWin here
      );

      // Make the PUT request
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Add token to the request header
          'Content-Type': 'application/json',
        },
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        print('Win or loss status updated successfully');
      } else {
        throw Exception(
            'Failed to update status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating win or loss status: $e');
    }
  }
}
