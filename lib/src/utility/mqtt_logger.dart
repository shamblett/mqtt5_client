// ignore_for_file: avoid-global-state

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Library wide logging class
class MqttLogger {
  /// Log or not
  static bool loggingOn = false;

  /// Test output
  static String testOutput = '';

  /// Test mode
  static bool testMode = false;

  /// Log publish message payload data
  static bool logPayloads = true;

  /// Log
  ///
  /// If the optimise parameter is supplied it must have a toString method,
  /// this allows large objects such as lots of payload data not to be
  /// converted into a string in the message parameter if logging is not enabled.
  static void log(String message, [dynamic optimise = false]) {
    if (loggingOn) {
      final now = DateTime.now();
      var output = '';
      output = optimise is bool
          ? '$now -- $message'
          : '$now -- $message$optimise';
      if (testMode) {
        testOutput = output;
      } else {
        print(output);
      }
    }
  }
}
