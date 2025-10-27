import 'dart:convert';
import 'dart:io';

void main() async {
  print('Starting performance test...\n');

  const String baseUrl = 'http://localhost:8080';
  final client = HttpClient();

  print('Testing against server at $baseUrl');

  // Create a few test notes first
  print('Setting up test data...');
  for (var i = 0; i < 10; i++) {
    final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
    request.headers.add('X-API-Key', 'test');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'title': 'Performance Test Note $i',
      'content': 'This is test content for performance testing'
    }));
    await request.close();
  }

  // Run performance test
  print('\nRunning 100 requests to /v1/notes (list endpoint)...\n');

  final latencies = <double>[];

  for (var i = 0; i < 100; i++) {
    final start = DateTime.now();

    final request = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
    request.headers.add('X-API-Key', 'test');
    final response = await request.close();
    await response.transform(utf8.decoder).join();

    final end = DateTime.now();
    final latencyMs = end.difference(start).inMicroseconds / 1000.0;
    latencies.add(latencyMs);

    if ((i + 1) % 10 == 0) {
      stdout.write('.');
    }
  }

  print('\n');
  client.close();

  // Calculate statistics
  latencies.sort();

  final min = latencies.first;
  final max = latencies.last;
  final avg = latencies.reduce((a, b) => a + b) / latencies.length;
  final p50 = latencies[(latencies.length * 0.5).floor()];
  final p95 = latencies[(latencies.length * 0.95).floor()];
  final p99 = latencies[(latencies.length * 0.99).floor()];

  // Print results
  print('Performance Test Results:');
  print('========================');
  print('Total requests: 100');
  print('Min latency:    ${min.toStringAsFixed(2)} ms');
  print('Max latency:    ${max.toStringAsFixed(2)} ms');
  print('Avg latency:    ${avg.toStringAsFixed(2)} ms');
  print('P50 latency:    ${p50.toStringAsFixed(2)} ms');
  print('P95 latency:    ${p95.toStringAsFixed(2)} ms');
  print('P99 latency:    ${p99.toStringAsFixed(2)} ms');
  print('');
  print('✅ Performance test completed!');
}
