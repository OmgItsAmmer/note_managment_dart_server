import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';

void main() async {
  print('Starting performance test...\n');

  // Set up server
  final notes = NotesController();
  final app = Router()..mount('/v1/notes', notes.router);
  final server = await io.serve(app, 'localhost', 0);
  final port = server.port;

  print('Server running on port $port');

  // Create a few test notes first
  final setupClient = HttpClient();
  for (var i = 0; i < 10; i++) {
    final req = await setupClient.post('localhost', port, '/v1/notes');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'title': 'Performance Test Note $i',
      'content': 'This is test content for performance testing'
    }));
    await req.close();
  }
  setupClient.close();

  // Run performance test
  print('\nRunning 100 requests to /v1/notes (list endpoint)...\n');

  final client = HttpClient();
  final latencies = <double>[];

  for (var i = 0; i < 100; i++) {
    final start = DateTime.now();

    final req = await client.get('localhost', port, '/v1/notes');
    final res = await req.close();
    await utf8.decodeStream(res);

    final end = DateTime.now();
    final latencyMs = end.difference(start).inMicroseconds / 1000.0;
    latencies.add(latencyMs);

    if ((i + 1) % 10 == 0) {
      stdout.write('.');
    }
  }

  print('\n');
  client.close();
  await server.close(force: true);

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
