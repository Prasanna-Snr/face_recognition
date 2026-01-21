import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchUserProfile(String phone) async {
  final response = await http.get(
    Uri.parse('http://172.16.0.212:8000/users/profile/$phone'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load user profile');
  }
}
