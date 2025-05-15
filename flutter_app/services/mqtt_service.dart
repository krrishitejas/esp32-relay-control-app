import 'package:mqtt_client/mqtt_client.dart';

class MQTTService {
  late MqttClient client;

  Future<void> connect(String broker, String clientId) async {
    client = MqttClient(broker, clientId);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(60);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print('MQTT Connection failed - $e');
    }
  }

  void onConnected() => print('MQTT Connected');
  void onDisconnected() => print('MQTT Disconnected');

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
  }
}
