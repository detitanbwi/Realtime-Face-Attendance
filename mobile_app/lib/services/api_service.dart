import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use your local IP if testing on real device, or 10.0.2.2 for Android Emulator
  // Adjust the port if your Laravel server runs on a different port (default 80 or 8000)
  static const String baseUrl = 'http://10.152.5.59/flutter-absen/web-admin/public/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String idPegawai, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'id_pegawai': idPegawai,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('user_name', data['user']['name']);
      await prefs.setString('user_id_pegawai', data['user']['id_pegawai']);
    }

    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id_pegawai');
  }

  Future<Map<String, dynamic>> checkIn(double lat, double long) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'lat': lat.toString(),
        'long': long.toString(),
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkOut(double lat, double long) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'lat': lat.toString(),
        'long': long.toString(),
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/history'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile(String name, String? password, {String? imagePath}) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/update-profile'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    
    request.fields['name'] = name;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }
    
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_photo', imagePath));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    
    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', data['user']['name']);
      if (data['user']['profile_photo_url'] != null) {
        await prefs.setString('profile_photo', data['user']['profile_photo_url']);
      }
    }

    return data;
  }

  Future<Map<String, dynamic>> getLeaveRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/leave-requests'),
      headers: await _getHeaders(),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> submitLeaveRequest({
    required String startDate,
    required String endDate,
    required String type,
    String? reason,
    String? attachmentPath,
  }) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/leave-requests'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    
    request.fields['start_date'] = startDate;
    request.fields['end_date'] = endDate;
    request.fields['type'] = type;
    if (reason != null && reason.isNotEmpty) request.fields['reason'] = reason;

    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('attachment', attachmentPath));
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return jsonDecode(responseData);
  }
}
