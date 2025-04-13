/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Generic enumeration helper class
class MqttEnumHelper<T extends dynamic> {
  /// Values map
  final Map<int, T> _valuesMap;

  /// Construction
  MqttEnumHelper(this._valuesMap);

  /// From int
  T? fromInt(int index) {
    if (_valuesMap.containsKey(index)) {
      return _valuesMap[index];
    }
    return null;
  }

  /// As int
  int? asInt(T code) {
    if (_valuesMap.containsValue(code)) {
      return _valuesMap.keys.firstWhere((int e) => _valuesMap[e] == code);
    }
    return null;
  }

  /// As string
  String asString(T name) => name.toString().split('.').last;
}
