/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// General library wide utilties
class MqttUtilities {
  /// Sleep function that allows asynchronous activity to continue.
  /// Time units are seconds
  static Future<void> asyncSleep(int seconds) =>
      Future<void>.delayed(Duration(seconds: seconds));

  /// Qos conversion, always use this to get a Qos
  /// enumeration from a value
  static MqttQos getQosLevel(int value) {
    switch (value) {
      case 0:
        return MqttQos.atMostOnce;
      case 1:
        return MqttQos.atLeastOnce;
      case 2:
        return MqttQos.exactlyOnce;
      case 0x80:
        return MqttQos.failure;
      default:
        return MqttQos.reserved1;
    }
  }

  /// Converts an array of bytes to a byte string.
  static String bytesToString(typed.Uint8Buffer message) {
    final sb = StringBuffer();
    for (final b in message) {
      sb.write('<');
      sb.write(b);
      sb.write('>');
    }
    return sb.toString();
  }

  /// Converts an array of bytes to a character string.
  static String bytesToStringAsString(typed.Uint8Buffer message) {
    return utf8.decode(message.toList());
  }
}

/// Cancellable asynchronous sleep support class
class MqttCancellableAsyncSleep {
  // Millisecond timeout
  final int _timeout;

  // The completer
  late Completer<void> _completer;

  // The timer
  late Timer _timer;

  // Timer running flag
  bool _running = false;

  /// Timeout
  int get timeout => _timeout;

  /// Running
  bool get isRunning => _running;

  /// Timeout value in milliseconds
  MqttCancellableAsyncSleep(this._timeout);

  /// Start the timer
  Future<void> sleep() {
    if (!_running) {
      _completer = Completer<void>();
      _timer = Timer(Duration(milliseconds: _timeout), _timerCallback);
      _running = true;
    }
    return _completer.future;
  }

  /// Cancel the timer
  void cancel() {
    if (_running) {
      _timer.cancel();
      _running = false;
      _completer.complete();
    }
  }

  /// The timer callback
  void _timerCallback() {
    _running = false;
    _completer.complete();
  }
}
