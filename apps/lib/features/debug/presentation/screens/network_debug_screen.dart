import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';

class NetworkDebugScreen extends StatelessWidget {
  const NetworkDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrimaryScaffold(
      title: 'Network Debug',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('WebSocket: disconnected'),
                Text('WebRTC ICE: new'),
                Text('RTT: -- ms'),
                Text('Clock offset: -- ms'),
                Text('Target buffer: Balanced'),
                Text('Drift estimate: -- ms'),
              ],
            ),
          ),
          Text('Live telemetry gets wired in during later phases.'),
        ],
      ),
    );
  }
}
