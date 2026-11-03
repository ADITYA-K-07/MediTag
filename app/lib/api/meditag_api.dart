import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../tag/ntag216.dart';

/// The website that hosts the API and the `/e/<tagId>` pages: `--dart-define=API_BASE_URL=…`
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://meditag-lovat.vercel.app');

class ApiException implements Exception {
  ApiException(this.message, this.status);
  final String message;
  final int status;
  @override
  String toString() => message;
}

/// What the server returns to program one tag (web/src/server/tags.ts → TagWriteResponse).
class TagWritePlan {
  TagWritePlan.fromJson(Map<String, dynamic> j)
      : tagId = j['tagId'] as String,
        uri = j['uri'] as String,
        mimeType = j['mimeType'] as String,
        envelope = base64.decode(j['envelope'] as String),
        androidPackage = j['androidPackage'] as String,
        password = TagPassword.fromHex(j['pwd'] as String, j['pack'] as String);

  final String tagId;
  final String uri;
  final String mimeType;
  final Uint8List envelope;
  final String androidPackage;
  final TagPassword password;
}

/// Calls the website's /api routes with the signed-in user's Firebase ID token.
class MeditagApi {
  Future<Map<String, dynamic>> _post(String path, [Map<String, Object?> body = const {}]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('Please log in.', 401);
    final res = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'content-type': 'application/json', 'authorization': 'Bearer ${await user.getIdToken()}'},
      body: jsonEncode(body),
    );
    final data = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(data['error'] as String? ?? 'Something went wrong. Please try again.', res.statusCode);
    }
    return data;
  }

  Future<TagWritePlan> prepareNewTag(String label) async => TagWritePlan.fromJson(await _post('/api/tags', {'label': label}));

  Future<TagWritePlan> prepareRewrite(String tagId) async => TagWritePlan.fromJson(await _post('/api/tags/$tagId/rewrite'));

  Future<void> confirmWritten(String tagId, String nfcUid) => _post('/api/tags/$tagId/confirm', {'nfcUid': nfcUid});
}
