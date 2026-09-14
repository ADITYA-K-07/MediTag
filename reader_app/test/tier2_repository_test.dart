import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meditag_reader/services/tier2_repository.dart';

void main() {
  test('missing build-time configuration keeps Tier 2 offline', () async {
    final result = await Tier2Repository(const ApiConfig(baseUrl: '', clinicianToken: '')).fetch(1001);
    expect(result, isA<Tier2Locked>());
    expect((result as Tier2Locked).reason, Tier2LockReason.offline);
  });

  test('sends the clinician token to the Tier 2 endpoint', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('{"tag_id":1001,"tier2":{"medications":["Insulin"]}}', 200);
    });
    final result = await Tier2Repository(const ApiConfig(baseUrl: 'https://api.example/', clinicianToken: 'demo-token'), client: client).fetch(1001);
    expect(captured.url.path, '/tags/1001/tier2');
    expect(captured.headers['authorization'], 'Bearer demo-token');
    expect((result as Tier2Record).values['medications'], ['Insulin']);
  });

  test('maps a forbidden response to the distinct authorization lock state', () async {
    final client = MockClient((_) async => http.Response('{"detail":"Verified clinician role required."}', 403));
    final result = await Tier2Repository(const ApiConfig(baseUrl: 'https://api.example/', clinicianToken: 'denied'), client: client).fetch(1001);
    expect((result as Tier2Locked).reason, Tier2LockReason.unauthorized);
  });
}
