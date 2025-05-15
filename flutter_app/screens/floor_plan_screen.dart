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
