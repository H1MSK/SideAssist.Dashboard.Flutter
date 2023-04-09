import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dashboard/config.dart';
import 'package:dashboard/manual_value_notifer.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class Dashboard {
  static const String clientIdentifier = "dashboard";

  static String get server => prefs.getString("server.host") as String;
  static set server(String value) => prefs.setString("server.host", value);

  static int get port => prefs.getInt("server.port") as int;
  static set port(int value) => prefs.setInt("server.port", value);

  // ...a.b.x < ...a.y
  //            ...a.y < ...b.z
  // a.x < y
  static int _fullNameComp(Client a, Client b) {
    if (a.category.isEmpty) {
      return b.category.isEmpty ? a.name.compareTo(b.name) : 1;
    }
    if (b.category.isEmpty) return -1;
    for (var i = 0;; ++i) {
      int ret;
      if (a.category.length == i + 1) {
        if (b.category.length > i + 1) return 1;
        ret = a.category[i].compareTo(b.category[i]);
        if (ret != 0) return ret;
        return a.name.compareTo(b.name);
      }
      if (b.category.length == i + 1) return 1;
      ret = a.category[i].compareTo(b.category[i]);
      if (ret != 0) return ret;
    }
  }

  final orderedClients = SplayTreeSet<Client>(_fullNameComp);
  final clientsNotifier = ManualValueNotifier(<String, Client>{});

  Map<String, Client> get indexedClients => clientsNotifier.value;

  final MqttClient mqttClient =
      MqttServerClient.withPort(server, clientIdentifier, port);

  void initialize() {
    mqttClient.keepAlivePeriod = 60;
    mqttClient.autoReconnect = true;
    mqttClient.resubscribeOnAutoReconnect = true;
    mqttClient.onConnected = _onConnected;
    mqttClient.onSubscribed = _onSubscribed;
    mqttClient.onDisconnected = _onDisconnected;
    mqttClient.connectionMessage = MqttConnectMessage().startClean();
  }

  Future<MqttClientConnectionStatus?> connect(
      [String? username, String? password]) async {
    return await mqttClient.connect(username, password);
  }

  void _onConnected() {
    mqttClient.updates!.listen(_onRawData);
    // mqttClient.subscribe("side_assist/+", MqttQos.atLeastOnce);
    mqttClient.subscribe("side_assist/+/option/+", MqttQos.atLeastOnce);
    mqttClient.subscribe(
        "side_assist/+/option/+/validator", MqttQos.atLeastOnce);
    mqttClient.subscribe("side_assist/+/param/+", MqttQos.atLeastOnce);
    mqttClient.subscribe(
        "side_assist/+/param/+/validator", MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    exit(1);
  }

  void _onSubscribed(String topic) {
    print("Subscribed to $topic");
  }

  void _onRawData(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      final payload = const Utf8Decoder().convert(recMess.payload.message);
      final topic = message.topic;
      var obj = jsonDecode(payload);
      _onIncomeMessage(topic, obj);
    }
  }

  void _onIncomeMessage(String topic, dynamic obj) {
    if (obj is! Map<String, dynamic>) {
      // TODO: log
      return;
    }
    var segments = topic.split('/');
    assert(segments[0] == "side_assist");
    var fullClientName = segments[1];
    var type = segments[2];
    var name = segments[3];
    var clientNameSections = fullClientName.split('.');
    final List<String> category = (clientNameSections.length > 1)
        ? clientNameSections.sublist(0, clientNameSections.length - 1)
        : [];
    var lastName = clientNameSections.last;
    bool isValidator = (segments.length >= 5 && segments[4] == "validator");

    var key = isValidator ? "validator" : "value";
    if (!obj.containsKey(key)) {
      // TODO: log
      return;
    }

    obj = obj[key];

    late final Client client;

    if (indexedClients.containsKey(fullClientName)) {
      client = indexedClients[fullClientName]!;
    } else {
      client = Client(category: category, name: lastName);
      indexedClients[fullClientName] = client;
      bool ret = orderedClients.add(client);
      assert(ret);
      clientsNotifier.notifyListeners();
    }

    if (type == "param") {
      if (isValidator) {
        var validator = client.originUpdateParamValidator(name, obj);
        print("Updated validator for param $name of client $fullClientName");
      } else {
        client.originUpdateParam(name, obj);
        print("Updated param $name of client $fullClientName");
      }
    } else if (type == "option") {
      if (isValidator) {
        client.originUpdateOptionValidator(name, obj);
        print("Updated validator for option $name of client $fullClientName");
      } else {
        client.originUpdateOption(name, obj);
        print("Updated option $name of client $fullClientName");
      }
    }
  }

  void changeOption(Client client, String optionName, dynamic value) {
    mqttClient.publishMessage(
        "side_assist/${client.name}/option/${optionName}/set",
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder()
            .addString(
                client.indexedOptions[optionName]?.type != ValueType.unknownType
                    ? jsonEncode({"value": value})
                    : '{"value":$value}')
            .payload!);
  }
}
