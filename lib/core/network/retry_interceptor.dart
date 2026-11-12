import 'dart:async';
import 'dart:math';

class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxRetries = 4,
    this.baseDelay = const Duration(milliseconds: 1500),
    this.maxDelay = const Duration(seconds: 30),
  });

  Future<T> executeWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    final random = Random();

    while (true) {
      try {
        attempts++;
        return await action();
      } catch (error) {
        if (attempts >= maxRetries) {
          rethrow;
        }

        final exponentialMillis =
            baseDelay.inMilliseconds * pow(2, attempts - 1).toInt();
        final jitter = random.nextInt(500);
        final delayMillis = min(
          maxDelay.inMilliseconds,
          exponentialMillis + jitter,
        );

        await Future<void>.delayed(Duration(milliseconds: delayMillis));
      }
    }
  }
}

