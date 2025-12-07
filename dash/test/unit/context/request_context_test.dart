import 'dart:async';
import 'dart:math';

import 'package:dash_board/src/context/request_context.dart';
import 'package:test/test.dart';

void main() {
  group('RequestContext', () {
    group('basic functionality', () {
      test('returns null for sessionId when not in request context', () {
        expect(RequestContext.sessionId, isNull);
      });

      test('returns null for user when not in request context', () {
        expect(RequestContext.user, isNull);
      });

      test('returns null for requestId when not in request context', () {
        expect(RequestContext.requestId, isNull);
      });

      test('isInRequestContext returns false when not in request context', () {
        expect(RequestContext.isInRequestContext, isFalse);
      });

      test('sessionId is available within run callback', () async {
        await RequestContext.run(
          sessionId: 'test-session-123',
          callback: () async {
            expect(RequestContext.sessionId, equals('test-session-123'));
          },
        );
      });

      test('user is available within run callback', () async {
        await RequestContext.run(
          sessionId: 'test-session',
          callback: () async {
            // user is null because we didn't set it
            expect(RequestContext.user, isNull);
          },
        );
      });

      test('requestId is generated within run callback', () async {
        await RequestContext.run(
          sessionId: 'test-session',
          callback: () async {
            expect(RequestContext.requestId, isNotNull);
            expect(RequestContext.requestId, isA<String>());
            expect(RequestContext.requestId!.isNotEmpty, isTrue);
          },
        );
      });

      test('isInRequestContext returns true within run callback', () async {
        await RequestContext.run(
          sessionId: 'test-session',
          callback: () async {
            expect(RequestContext.isInRequestContext, isTrue);
          },
        );
      });

      test('context is available through async operations', () async {
        await RequestContext.run(
          sessionId: 'async-test-session',
          callback: () async {
            expect(RequestContext.sessionId, equals('async-test-session'));

            // Simulate async database call
            await Future.delayed(const Duration(milliseconds: 10));

            // Context should still be correct after await
            expect(RequestContext.sessionId, equals('async-test-session'));

            // Simulate another async operation
            await Future.delayed(const Duration(milliseconds: 5));

            // Still correct
            expect(RequestContext.sessionId, equals('async-test-session'));
          },
        );
      });

      test('each request gets a unique requestId', () async {
        final requestIds = <String>[];

        for (var i = 0; i < 10; i++) {
          await RequestContext.run(
            sessionId: 'session-$i',
            callback: () async {
              requestIds.add(RequestContext.requestId!);
            },
          );
        }

        // All request IDs should be unique
        expect(requestIds.toSet().length, equals(10));
      });
    });

    group('concurrent request isolation', () {
      test('concurrent requests have isolated session IDs', () async {
        final results = <String, String>{};
        final random = Random();

        // Simulate 100 concurrent requests with different sessions
        await Future.wait(
          List.generate(100, (i) async {
            final expectedSessionId = 'session_$i';

            await RequestContext.run(
              sessionId: expectedSessionId,
              callback: () async {
                // Simulate variable processing time
                await Future.delayed(Duration(milliseconds: random.nextInt(20)));

                // Verify session ID is still correct
                final actualSessionId = RequestContext.sessionId;

                // Store result for verification
                results[expectedSessionId] = actualSessionId ?? 'null';
              },
            );
          }),
        );

        // Verify all 100 requests saw their own session ID
        expect(results.length, equals(100));
        for (var i = 0; i < 100; i++) {
          expect(
            results['session_$i'],
            equals('session_$i'),
            reason: 'Request $i should see session_$i but saw ${results['session_$i']}',
          );
        }
      });

      test('nested async operations maintain correct context', () async {
        final results = <int, List<String>>{};

        await Future.wait(
          List.generate(50, (i) async {
            final expectedSessionId = 'nested_session_$i';

            await RequestContext.run(
              sessionId: expectedSessionId,
              callback: () async {
                final captured = <String>[];

                // Capture session at start
                captured.add(RequestContext.sessionId ?? 'null');

                // First await
                await Future.delayed(const Duration(milliseconds: 2));
                captured.add(RequestContext.sessionId ?? 'null');

                // Call a nested async function
                await _nestedAsyncCall(captured);

                // After nested call
                captured.add(RequestContext.sessionId ?? 'null');

                results[i] = captured;
              },
            );
          }),
        );

        // Verify each request saw only its own session ID at all points
        for (var i = 0; i < 50; i++) {
          final expectedSessionId = 'nested_session_$i';
          final captures = results[i]!;

          for (var j = 0; j < captures.length; j++) {
            expect(
              captures[j],
              equals(expectedSessionId),
              reason: 'Request $i capture $j should be $expectedSessionId but was ${captures[j]}',
            );
          }
        }
      });

      test('deeply nested async operations maintain context', () async {
        final results = <String>[];

        await Future.wait(
          List.generate(20, (i) async {
            await RequestContext.run(
              sessionId: 'deep_$i',
              callback: () async {
                final result = await _deeplyNestedOp(5);
                results.add(result);
              },
            );
          }),
        );

        // Should have 20 results, each being 'deep_X'
        expect(results.length, equals(20));
        for (final result in results) {
          expect(result.startsWith('deep_'), isTrue);
        }
      });

      test('interleaved requests do not cross-contaminate', () async {
        // This test specifically simulates the race condition scenario:
        // Request A starts, then yields (await)
        // Request B starts and sets its session
        // Request A resumes - should still see its own session

        final completers = <int, Completer<void>>{};
        final results = <int, String>{};

        // Set up completers to control execution order
        for (var i = 0; i < 10; i++) {
          completers[i] = Completer<void>();
        }

        // Start all requests
        final futures = <Future<void>>[];

        for (var i = 0; i < 10; i++) {
          futures.add(
            RequestContext.run(
              sessionId: 'interleaved_$i',
              callback: () async {
                // Wait for our specific completer
                await completers[i]!.future;

                // After being released, verify our session is still correct
                results[i] = RequestContext.sessionId ?? 'null';
              },
            ),
          );
        }

        // Complete them in reverse order to maximize interleaving
        for (var i = 9; i >= 0; i--) {
          completers[i]!.complete();
          // Small delay to allow processing
          await Future.delayed(const Duration(milliseconds: 1));
        }

        await Future.wait(futures);

        // Verify each request saw its own session
        for (var i = 0; i < 10; i++) {
          expect(
            results[i],
            equals('interleaved_$i'),
            reason: 'Interleaved request $i should see interleaved_$i but saw ${results[i]}',
          );
        }
      });

      test('stress test with high concurrency', () async {
        const concurrency = 500;
        final errors = <String>[];
        final random = Random();

        await Future.wait(
          List.generate(concurrency, (i) async {
            final expectedSessionId = 'stress_$i';

            await RequestContext.run(
              sessionId: expectedSessionId,
              callback: () async {
                // Multiple checkpoints with random delays
                for (var check = 0; check < 5; check++) {
                  await Future.delayed(Duration(microseconds: random.nextInt(1000)));

                  final actualSessionId = RequestContext.sessionId;
                  if (actualSessionId != expectedSessionId) {
                    errors.add('Request $i check $check: expected $expectedSessionId, got $actualSessionId');
                  }
                }
              },
            );
          }),
        );

        expect(errors, isEmpty, reason: 'Found ${errors.length} isolation violations: ${errors.take(5).join(', ')}');
      });
    });

    group('context values', () {
      test('null sessionId is valid', () async {
        await RequestContext.run(
          sessionId: null,
          callback: () async {
            expect(RequestContext.sessionId, isNull);
            expect(RequestContext.isInRequestContext, isTrue);
          },
        );
      });

      test('empty string sessionId is preserved', () async {
        await RequestContext.run(
          sessionId: '',
          callback: () async {
            expect(RequestContext.sessionId, equals(''));
          },
        );
      });
    });
  });
}

/// Helper function for nested async test
Future<void> _nestedAsyncCall(List<String> captured) async {
  await Future.delayed(const Duration(milliseconds: 1));
  captured.add(RequestContext.sessionId ?? 'null');
  await Future.delayed(const Duration(milliseconds: 1));
  captured.add(RequestContext.sessionId ?? 'null');
}

/// Helper function for deeply nested async test
Future<String> _deeplyNestedOp(int depth) async {
  await Future.delayed(const Duration(microseconds: 100));
  if (depth <= 0) {
    return RequestContext.sessionId ?? 'null';
  }
  return _deeplyNestedOp(depth - 1);
}
