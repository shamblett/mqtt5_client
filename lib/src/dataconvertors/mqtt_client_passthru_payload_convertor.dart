/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

///  Acts as a pass through for the raw data without doing any conversion.
class PassthruPayloadConverter implements PayloadConverter<typed.Uint8Buffer> {
  /// Processes received data and returns it as a byte array.
  @override
  typed.Uint8Buffer convertFromBytes(typed.Uint8Buffer messageData) =>
      messageData;

  /// Converts sent data from an object graph to a byte array.
  @override
  typed.Uint8Buffer convertToBytes(typed.Uint8Buffer data) => data;
}
