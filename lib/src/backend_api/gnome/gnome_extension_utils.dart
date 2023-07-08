import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:shell/shell.dart';

/// Utility class for managing Gnome extensions.
class GnomeExtensionUtils {
  static Future<DBusMethodSuccessResponse> installRemoteExtension(String uuid) {
    // dbus-send --session --type=method_call --print-reply --dest=org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions.InstallRemoteExtension string:caffeine@patapon.info
    var dBusClient = DBusClient.session();
    return dBusClient.callMethod(
        destination: "org.gnome.Shell.Extensions",
        path: DBusObjectPath("/org/gnome/Shell/Extensions"),
        name: "InstallRemoteExtension",
        interface: "org.gnome.Shell.Extensions",
        values: [DBusString(uuid)]);
  }

  static Future<ProcessResult> enableDisableExtension(
      String extensionName, bool enabled) {
    var shell = Shell();
    return shell.run('gnome-extensions',
        arguments: [enabled ? 'enable' : 'disable', extensionName]);
  }
}
