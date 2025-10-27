import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  group('Feature Flags Service Tests', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('Should return Sandbox tier for unknown key', () async {
      final request = await server.client
          .getUrl(Uri.parse('${server.baseUrl}/v1/feature-flags'));
      request.headers.add('X-API-Key', 'unknown_key');
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Sandbox');
      expect(data['features']['notesCrud'], true);
      expect(data['features']['oauth'], false);
      expect(data['features']['advancedReports'], false);
    });

    test('Should return Standard tier features', () async {
      final request = await server.client
          .getUrl(Uri.parse('${server.baseUrl}/v1/feature-flags'));
      request.headers.add('X-API-Key', 'key_standard');
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Standard');
      expect(data['features']['notesCrud'], true);
      expect(data['features']['oauth'], true);
      expect(data['features']['advancedReports'], false);
    });

    test('Should return Enhanced tier features', () async {
      final request = await server.client
          .getUrl(Uri.parse('${server.baseUrl}/v1/feature-flags'));
      request.headers.add('X-API-Key', 'key_enhanced');
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Enhanced');
      expect(data['features']['notesCrud'], true);
      expect(data['features']['oauth'], true);
      expect(data['features']['advancedReports'], true);
    });

    test('Should return Enterprise tier features with SSO', () async {
      final request = await server.client
          .getUrl(Uri.parse('${server.baseUrl}/v1/feature-flags'));
      request.headers.add('X-API-Key', 'key_enterprise');
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Enterprise');
      expect(data['features']['notesCrud'], true);
      expect(data['features']['oauth'], true);
      expect(data['features']['advancedReports'], true);
      expect(data['features']['ssoSaml'], true);
    });

    test('Should return Sandbox for null API key', () async {
      final request = await server.client
          .getUrl(Uri.parse('${server.baseUrl}/v1/feature-flags'));
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Sandbox');
    });
  });
}
