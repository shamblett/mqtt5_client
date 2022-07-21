import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart' as typed;
import 'package:test/test.dart';

Future<int> main() async {
  test('Property Handling', () {
    final user1 = MqttUserProperty();
    user1.pairName = 'User 1 name';
    user1.pairValue = 'User 1 value';
    final user2 = MqttUserProperty();
    user2.pairName = 'User 2 name';
    user2.pairValue = 'User 2 value';

    final message = MqttAuthenticateMessage()
        .withReasonCode(MqttAuthenticateReasonCode.success)
        .withAuthenticationMethod('method')
        .withAuthenticationData(typed.Uint8Buffer()..addAll([1, 2, 3, 4]))
        .withUserProperties([user1]).withReasonString('Reason String');

    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    message.writeTo(stream);
    stream.reset();
    final outputHeader = MqttHeader.fromByteBuffer(stream);
    final message2 =
        MqttAuthenticateMessage.fromByteBuffer(outputHeader, stream);

    expect(message.userProperties.length, 1); // 1
    expect(message2.userProperties.length, 1); // 1

    message.addUserProperty(user2);
    message2.addUserProperty(user2);

    expect(message.userProperties.length, 2); // 2
    expect(message2.userProperties.length, 2); // 3 <should be 2>
  });

  return 0;
}
