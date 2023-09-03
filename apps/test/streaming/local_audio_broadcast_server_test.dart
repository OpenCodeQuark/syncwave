import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/local_audio_broadcast_server.dart';

void main() {
  group('LocalAudioBroadcastServer', () {
    late LocalAudioBroadcastServer server;

    setUp(() {
      server = LocalAudioBroadcastServer();
    });

    tearDown(() async {
      await server.dispose();
    });

    test(
      'serves mobile-friendly browser join page with ws/wss selection',
      () async {
        await server.start(host: '192.168.1.20', port: 0, roomId: 'LAN-R12B9');
        final port = server.port!;

        final client = HttpClient();
        final request = await client.get(
          '127.0.0.1',
          port,
          '/stream/join?room=LAN-R12B9',
        );
        final response = await request.close();
        final html = await response.transform(utf8.decoder).join();

        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers.contentType?.mimeType,
          ContentType.html.mimeType,
        );
        expect(html, contains('<h1>SyncWave</h1>'));
        expect(html, contains('Play'));
        expect(html, contains('Volume'));
        expect(html, contains("location.protocol === 'https:' ? 'wss' : 'ws'"));
        expect(html, contains('/stream/audio'));
        expect(html, contains('LAN-R12B9'));
        client.close(force: true);
      },
    );

    test('join page asks for room when room is missing', () async {
      await server.start(host: '192.168.1.20', port: 0, roomId: '');
      final port = server.port!;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/stream/join');
      final response = await request.close();
      final html = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(html, contains('placeholder="LAN-ABCDE or WAN-ABCDE"'));
      client.close(force: true);
    });

    test('redirects root route to stream join path', () async {
      await server.start(host: '192.168.1.20', port: 0, roomId: 'LAN-R12B9');
      final port = server.port!;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/');
      request.followRedirects = false;
      final response = await request.close();

      expect(response.statusCode, HttpStatus.temporaryRedirect);
      expect(
        response.headers.value(HttpHeaders.locationHeader),
        '/stream/join?room=LAN-R12B9',
      );
      client.close(force: true);
    });

    test('rejects invalid room PIN on websocket join path', () async {
      await server.start(host: '192.168.1.20', port: 0, roomId: 'LAN-R12B9');
      final port = server.port!;

      await expectLater(
        () => WebSocket.connect(
          'ws://127.0.0.1:$port/stream/audio?room=LAN-R12B9&pin=12345',
        ),
        throwsException,
      );
    });

    test('requires room PIN when room is PIN protected', () async {
      await server.start(
        host: '192.168.1.20',
        port: 0,
        roomId: 'LAN-R12B9',
        roomPinProtected: true,
        roomPin: '123456',
      );
      final port = server.port!;

      await expectLater(
        () => WebSocket.connect(
          'ws://127.0.0.1:$port/stream/audio?room=LAN-R12B9',
        ),
        throwsException,
      );

      final socket = await WebSocket.connect(
        'ws://127.0.0.1:$port/stream/audio?room=LAN-R12B9&pin=123456',
      );
      await socket.close();
    });

    test('supports websocket metadata and audio event broadcast', () async {
      await server.start(host: '192.168.1.20', port: 0, roomId: 'LAN-R12B9');
      final port = server.port!;

      final socket = await WebSocket.connect(
        'ws://127.0.0.1:$port/stream/audio?room=LAN-R12B9',
      );
      expect(server.listenerCount, 1);

      final iterator = StreamIterator<dynamic>(socket);
      Map<String, dynamic>? metaEvent;
      for (var i = 0; i < 6; i++) {
        if (!await iterator.moveNext()) {
          break;
        }
        final event = jsonDecode(iterator.current as String);
        if (event is Map<String, dynamic> && event['type'] == 'stream.meta') {
          metaEvent = event;
          break;
        }
      }

      expect(metaEvent, isNotNull);
      expect(metaEvent!['roomId'], 'LAN-R12B9');

      await server.broadcast(Uint8List.fromList(<int>[1, 2, 3, 4]));

      Map<String, dynamic>? audioEvent;
      for (var i = 0; i < 6; i++) {
        if (!await iterator.moveNext()) {
          break;
        }
        final event = jsonDecode(iterator.current as String);
        if (event is Map<String, dynamic> && event['type'] == 'stream.audio') {
          audioEvent = event;
          break;
        }
      }

      expect(audioEvent, isNotNull);
      expect(audioEvent!['roomId'], 'LAN-R12B9');
      expect(audioEvent['payload'], isNotEmpty);
      expect(audioEvent['durationMs'], greaterThanOrEqualTo(0));

      await socket.close();
      await iterator.cancel();
      await server.stop();
      expect(server.listenerCount, 0);
    });

    test('notifies listeners when host stops stream', () async {
      await server.start(host: '192.168.1.20', port: 0, roomId: 'LAN-R12B9');
      final port = server.port!;

      final socket = await WebSocket.connect(
        'ws://127.0.0.1:$port/stream/audio?room=LAN-R12B9',
      );
      final iterator = StreamIterator<dynamic>(socket);
      var sawHostStopped = false;

      await server.stop();

      for (var i = 0; i < 10; i++) {
        if (!await iterator.moveNext()) {
          break;
        }
        final event = jsonDecode(iterator.current as String);
        if (event is Map<String, dynamic> &&
            event['type'] == 'stream.host_stopped') {
          sawHostStopped = true;
          break;
        }
      }

      expect(sawHostStopped, isTrue);
      await iterator.cancel();
      await socket.close();
    });
  });
}
