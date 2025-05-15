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
