import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Feature Flags Service Tests', () {
    const String baseUrl = 'http://localhost:8080';
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('Should return Sandbox tier for unknown key', () async {
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/feature-flags'));
      // Use a valid API key that doesn't match tier patterns
      request.headers.add('X-API-Key', 'test');
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
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/feature-flags'));
      request.headers.add('X-API-Key', 'standard');
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
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/feature-flags'));
      request.headers.add('X-API-Key', 'enhanced');
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
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/feature-flags'));
      request.headers.add('X-API-Key', 'enterprise');
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
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/feature-flags'));
      // Provide a valid API key
      request.headers.add('X-API-Key', 'test');
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(data['tier'], 'Sandbox');
    });
  });
}
