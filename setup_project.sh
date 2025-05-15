#!/bin/bash

echo "🚀 Creating ESP32 Relay Control App Project Structure..."

# Root level README
cat <<EOT > README.md
# ESP32 Relay Control System with Energy Monitoring

A complete IoT system to control relays (lights/fans), monitor energy usage, and manage access via mobile app and admin panel.

## 🔧 Features

- 📱 Cross-platform mobile app (Flutter)
- 💡 Tap-to-control lights/fans in staffroom
- 🗺️ SVG-based floor plan view
- ⚡ Real-time energy monitoring & analytics
- 🎛️ Scene creation & scheduling
- 📥 FOTA (Firmware Over-The-Air) updates
- 🌐 MQTT communication between devices
- 🖥️ Firebase-powered admin dashboard
- 🧪 Node-RED visualization dashboard

## 📁 Project Structure

| Folder | Description |
|--------|-------------|
| \`flutter_app/\` | Mobile app for device control |
| \`esp32_firmware/\` | Arduino code for ESP32 master/slave nodes |
| \`nodered_dashboard/\` | Node-RED flow for visualizing data |
| \`firebase_admin_panel/\` | Firebase web dashboard for admins |
| \`docs/\` | Guides, diagrams, and documentation |

## 📝 Setup Instructions

See individual READMEs inside each folder for detailed setup steps.
EOT

# Create flutter_app folder
mkdir -p flutter_app/{lib,screens,services,models,utils,widgets,assets/svg,assets/images}

# pubspec.yaml
cat <<EOT > flutter_app/pubspec.yaml
name: esp32_relay_app
description: ESP32 Relay Control App with MQTT & Energy Monitoring
version: 1.0.0+1

environment:
  sdk: ">=2.18.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  mqtt_client: ^9.2.0
  flutter_svg: ^2.0.0
  charts_flutter: ^0.14.0
  http: ^0.15.0
  shared_preferences: ^2.2.0
  provider: ^6.1.1
  firebase_auth: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/svg/
EOT

# main.dart
cat <<EOT > flutter_app/lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staffroom Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
EOT

# Home Screen
cat <<EOT > flutter_app/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staffroom Controller')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Tap on a device to control it', style: TextStyle(fontSize: 18)),
            Expanded(
              child: SvgPicture.asset('assets/svg/staff_room_map.svg'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FloorPlanScreen()));
              },
              icon: const Icon(Icons.map),
              label: const Text('Open Floor Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
EOT

# Floor Plan Screen
cat <<EOT > flutter_app/screens/floor_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloorPlanScreen extends StatelessWidget {
  const FloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floor Plan')),
      body: Center(
        child: SvgPicture.asset('assets/svg/staff_room_map.svg'),
      ),
    );
  }
}
EOT

# MQTT Service
cat <<EOT > flutter_app/services/mqtt_service.dart
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
      print('MQTT Connection failed - \$e');
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
EOT

# Device Card
cat <<EOT > flutter_app/widgets/device_card.dart
import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final bool isOn;
  final VoidCallback onTap;

  const DeviceCard({super.key, required this.name, required this.isOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isOn ? Colors.blue.shade100 : null,
      child: ListTile(
        title: Text(name),
        trailing: Switch(value: isOn, onChanged: (_) => onTap()),
      ),
    );
  }
}
EOT

# Sample SVG
mkdir -p flutter_app/assets/svg
cat <<EOT > flutter_app/assets/svg/staff_room_map.svg
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="400" height="300" fill="#f0f0f0"/>
  <text x="100" y="150" font-size="24" fill="#333">Staff Room Map</text>
</svg>
EOT

# ESP32 Firmware
mkdir -p esp32_firmware/master_controller
cat <<EOT > esp32_firmware/master_controller/master_controller.ino
#include <WiFi.h>
#include <PubSubClient.h>

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "192.168.x.x"; // IP of your MQTT broker

WiFiClient espClient;
PubSubClient client(espClient);

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
}

void reconnect() {
  while (!client.connect("master")) {
    delay(1000);
    Serial.print(".");
  }
  client.subscribe("switch/#");
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(500);
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();
}
EOT

mkdir -p esp32_firmware/slave_relay_node
cat <<EOT > esp32_firmware/slave_relay_node/slave_relay_node.ino
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
EOT

# Node-RED Dashboard
mkdir -p nodered_dashboard
cat <<EOT > nodered_dashboard/flow.json
[
  {
    "id": "mqtt-broker",
    "type": "mqtt-broker",
    "name": "Local MQTT",
    "broker": "192.168.x.x",
    "port": "1883",
    "clientid": "node-red-dashboard"
  },
  {
    "id": "energy-subscriber",
    "type": "mqtt in",
    "topic": "energy",
    "qos": "2",
    "broker": "mqtt-broker",
    "name": "Energy Data"
  },
  {
    "id": "gauge",
    "type": "ui_gauge",
    "group": "dashboard-group",
    "order": 1,
    "width": 0,
    "height": 0,
    "name": "Power Usage",
    "label": "Watts",
    "format": "{{value}} W",
    "min": 0,
    "max": "500",
    "colors": ["#00b500","#e6e600","#ca3838"]
  }
]
EOT

# Firebase Admin Panel
mkdir -p firebase_admin_panel
cat <<EOT > firebase_admin_panel/package.json
{
  "name": "firebase-admin-panel",
  "version": "1.0.0",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "dependencies": {
    "firebase": "^9.23.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOT

cat <<EOT > firebase_admin_panel/src/App.js
import React from 'react';
import { initializeApp } from 'firebase/app';
import { getDatabase, ref, onValue } from 'firebase/database';

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  databaseURL: "https://your-project.firebaseio.com ",
  projectId: "your-project",
  appId: "your-app-id"
};

const app = initializeApp(firebaseConfig);
const db = getDatabase(app);

function App() {
  return (
    <div style={{ padding: 20 }}>
      <h1>Staffroom Admin Panel</h1>
      <p>Real-time device status and analytics coming soon.</p>
    </div>
  );
}

export default App;
EOT

# Docs folder
mkdir -p docs
cat <<EOT > docs/mqtt_setup_guide.md
# MQTT Broker Setup Guide

To set up your local MQTT broker:

1. Install Mosquitto:
   \`\`\`
   sudo apt install mosquitto
   \`\`\`

2. Start the service:
   \`\`\`
   sudo systemctl start mosquitto
   \`\`\`

3. Enable on boot:
   \`\`\`
   sudo systemctl enable mosquitto
   \`\`\`

4. Test connection:
   \`\`\`
   mosquitto_sub -t "test" -v
   mosquitto_pub -t "test" -m "hello"
   \`\`\`
EOT

echo "✅ Done! All files created."