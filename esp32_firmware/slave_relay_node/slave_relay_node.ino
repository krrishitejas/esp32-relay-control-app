#include <WiFi.h>
#include <PubSubClient.h>

#define DEVICE_ID "switchboard_1"
#define RELAY_PIN 13

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "192.168.x.x";

WiFiClient espClient;
PubSubClient client(espClient);

void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  if (message == "ON") {
    digitalWrite(RELAY_PIN, HIGH);
  } else if (message == "OFF") {
    digitalWrite(RELAY_PIN, LOW);
  }
}

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(500);
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    while (!client.connect(DEVICE_ID)) delay(1000);
    client.subscribe(("switch/" + String(DEVICE_ID)).c_str());
  }
  client.loop();
}
