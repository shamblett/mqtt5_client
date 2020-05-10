/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Library wide logging class
class MqttLogger {
  /// Log or not
  static bool loggingOn = false;

  /// Log method
  static void log(String message) {
    if (loggingOn) {
      final now = DateTime.now();
      print('$now -- $message');
    }
  }
}
