import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      title: 'Listener Room',
      child: ListView(
        children: [
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text('Room'),
                Text(
                  roomId,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Host: Unknown host'),
                const Text('Connection: Disconnected'),
                const Text('Buffering state: Idle'),
                const Text('Estimated latency: -- ms'),
                const Text('Drift estimate: -- ms'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: null,
            icon: Icon(Icons.logout),
            label: Text('Leave Session'),
          ),
        ],
      ),
    );
  }
}
