import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';

/// Abstract class representing the backend for the "Awake" utility.
abstract class AwakeBackend extends UtilityBackend {
  /// Last "keep awake" value
  bool get lastKeepAwake;

  /// Stream for the "keep awake" status.
  Stream<bool> get keepAwake;

  /// Sets the "keep awake" status to the specified [newValue].
  setKeepAwake(bool newValue);
}