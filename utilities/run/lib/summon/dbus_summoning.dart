import 'dart:developer' as developer;

import 'package:dbus/dbus.dart';

import '../run.dart';

const String runDBusInterface = "com.github.LinuxPowerToys.run";

class DBusSummon extends DBusObject {
  DBusSummon({required this.runModel, DBusObjectPath path = const DBusObjectPath.unchecked('/')}) : super(path);

  final RunModel runModel;

  static Future<void> register(RunModel runModel) async {
    DBusClient client = DBusClient.session();
    client.requestName(runDBusInterface);
    client.nameLost.listen((event) {
      developer.log("lost name $event");
    });
    client.nameAcquired.listen((event) {
      developer.log("got name $event");
    });
    await client.registerObject(DBusSummon(
      runModel: runModel,
    ));
  }

  bool visible = true;

  Future<DBusMethodResponse> doToggleVisibility() async {
    runModel.summon();
    return DBusMethodSuccessResponse();
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(runDBusInterface, methods: [DBusIntrospectMethod('toggleVisibility')])
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == runDBusInterface) {
      if (methodCall.name == 'toggleVisibility') {
        if (methodCall.values.isNotEmpty) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return doToggleVisibility();
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == runDBusInterface) {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(String interface, String name, DBusValue value) async {
    if (interface == runDBusInterface) {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }
}
