/// Abstract class defining the common interface for utility backends.
abstract class UtilityBackend {
  /// Returns whether the utility is currently enabled.
  Future<bool> isEnabled();

  /// Enables or disables the utility based on the [newValue] provided.
  Future<bool> enable(bool newValue);

  /// Returns whether the utility is installed.
  Future<bool> isInstalled();

  /// Installs the utility.
  Future<void> install();

  /// Cleans up any resources used by the backend.
  void dispose();
}
