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
