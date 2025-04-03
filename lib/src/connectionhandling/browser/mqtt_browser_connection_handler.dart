/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_browser_client.dart';

///  This class provides specific connection functionality
///  for browser based connection handler implementations.
abstract class MqttBrowserConnectionHandler extends MqttConnectionHandlerBase {
  /// Initializes a new instance of the [MqttBrowserConnectionHandler] class.
  MqttBrowserConnectionHandler(
    super.clientEventBus, {
    required int super.maxConnectionAttempts,
  });
}
