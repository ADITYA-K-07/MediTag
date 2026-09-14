import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.clinicianToken});

  factory ApiConfig.fromEnvironment() => const ApiConfig(
        baseUrl: String.fromEnvironment('MEDITAG_API_BASE_URL'),
        clinicianToken: String.fromEnvironment('MEDITAG_CLINICIAN_TOKEN'),
      );

  final String baseUrl;
  final String clinicianToken;
  bool get isConfigured => baseUrl.isNotEmpty && clinicianToken.isNotEmpty;
}

sealed class Tier2Result {
  const Tier2Result();
}

class Tier2Record extends Tier2Result {
  const Tier2Record(this.values);
  final Map<String, dynamic> values;
}

enum Tier2LockReason { offline, unauthorized }

class Tier2Locked extends Tier2Result {
  const Tier2Locked(this.reason);
  final Tier2LockReason reason;
}

class Tier2Repository {
  Tier2Repository(this._config, {http.Client? client}) : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  Future<Tier2Result> fetch(int tagId) async {
    if (!_config.isConfigured) return const Tier2Locked(Tier2LockReason.offline);
    try {
      final response = await _client.get(
        Uri.parse(_config.baseUrl).resolve('/tags/$tagId/tier2'),
        headers: {'Authorization': 'Bearer ${_config.clinicianToken}'},
      );
      if (response.statusCode == 403) return const Tier2Locked(Tier2LockReason.unauthorized);
      if (response.statusCode != 200) return const Tier2Locked(Tier2LockReason.offline);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final record = decoded['tier2'];
      if (record is! Map) return const Tier2Locked(Tier2LockReason.offline);
      return Tier2Record(Map<String, dynamic>.from(record));
    } catch (_) {
      return const Tier2Locked(Tier2LockReason.offline);
    }
  }
}
