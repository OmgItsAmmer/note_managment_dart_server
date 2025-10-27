import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_backend_tech_test/src/services/feature_flags.dart';

void main() {
  group('Feature Flags Service Tests', () {
    test('Should return Sandbox tier for unknown key', () async {
      final request =
          Request('GET', Uri.parse('http://localhost/v1/feature-flags'))
              .change(context: {'apiKey': 'unknown_key'});

      final response = await FeatureFlagsService.handleGet(request);
      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['tier'], 'Sandbox');
      expect(body['features']['notesCrud'], true);
      expect(body['features']['oauth'], false);
      expect(body['features']['advancedReports'], false);
    });

    test('Should return Standard tier features', () async {
      final request =
          Request('GET', Uri.parse('http://localhost/v1/feature-flags'))
              .change(context: {'apiKey': 'key_standard'});

      final response = await FeatureFlagsService.handleGet(request);
      final body = jsonDecode(await response.readAsString());

      expect(body['tier'], 'Standard');
      expect(body['features']['notesCrud'], true);
      expect(body['features']['oauth'], true);
      expect(body['features']['advancedReports'], false);
    });

    test('Should return Enhanced tier features', () async {
      final request =
          Request('GET', Uri.parse('http://localhost/v1/feature-flags'))
              .change(context: {'apiKey': 'key_enhanced'});

      final response = await FeatureFlagsService.handleGet(request);
      final body = jsonDecode(await response.readAsString());

      expect(body['tier'], 'Enhanced');
      expect(body['features']['notesCrud'], true);
      expect(body['features']['oauth'], true);
      expect(body['features']['advancedReports'], true);
    });

    test('Should return Enterprise tier features with SSO', () async {
      final request =
          Request('GET', Uri.parse('http://localhost/v1/feature-flags'))
              .change(context: {'apiKey': 'key_enterprise'});

      final response = await FeatureFlagsService.handleGet(request);
      final body = jsonDecode(await response.readAsString());

      expect(body['tier'], 'Enterprise');
      expect(body['features']['notesCrud'], true);
      expect(body['features']['oauth'], true);
      expect(body['features']['advancedReports'], true);
      expect(body['features']['ssoSaml'], true);
    });

    test('Should return Sandbox for null API key', () async {
      final request =
          Request('GET', Uri.parse('http://localhost/v1/feature-flags'));

      final response = await FeatureFlagsService.handleGet(request);
      final body = jsonDecode(await response.readAsString());

      expect(body['tier'], 'Sandbox');
    });
  });
}
