import 'package:linuxpowertoys/src/backend_api/utility_backend.dart';

/// Abstract class representing the backend for the "Awake" utility.
abstract class ColorPickerBackend extends UtilityBackend {
  /// Last "colors history" value
  List<String> get lastColorsHistory;

  /// Stream for the "colors history" status.
  Stream<List<String>> get colorsHistory;

  /// Sets the "colors history" status to the specified [newValue].
  setColorsHistory(List<String> newValue);

  /// Last "automatically copy" value
  bool get lastAutomaticallyCopy;

  /// Stream for the "automatically copy" status.
  Stream<bool> get automaticallyCopy;

  /// Sets the "automatically copy" status to the specified [newValue].
  setAutomaticallyCopy(bool newValue);
}
