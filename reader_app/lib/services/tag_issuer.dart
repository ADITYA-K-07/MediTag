import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tier2_repository.dart';

class IssuedTag {
  const IssuedTag({required this.tagId, required this.payload});

  final int tagId;
  final Uint8List payload;
}

class TagIssuer {
  TagIssuer(this._config, {http.Client? client})
    : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  Future<IssuedTag> issue({
    required int tagId,
    required int bloodType,
    required String emergencyPhone,
  }) async {
    if (!_config.isIssueConfigured) {
      throw StateError(
        'Set MEDITAG_API_BASE_URL and MEDITAG_ADMIN_TOKEN before issuing a tag.',
      );
    }

    final response = await _client.post(
      Uri.parse(_config.baseUrl).resolve('/tags/issue'),
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-Token': _config.adminToken,
      },
      body: jsonEncode({
        'tag_id': tagId,
        'blood_type': bloodType,
        'allergies': <String>[],
        'critical_conditions': <String>[],
        'emergency_phone': emergencyPhone,
        'tier2_record': <String, Object>{},
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Tag issuance failed (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final encoded = body['ndef_payload_base64'];
    if (encoded is! String) {
      throw const FormatException('The issuer returned no NDEF payload.');
    }
    final payload = Uint8List.fromList(base64Decode(encoded));
    if (payload.length != 79) {
      throw FormatException(
        'The issuer returned ${payload.length} bytes; expected 79.',
      );
    }
    return IssuedTag(tagId: tagId, payload: payload);
  }
}
