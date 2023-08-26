import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      title: 'About SyncWave',
      child: ListView(
        children: const [
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'SyncWave is a local-first live audio broadcast app.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'v1.0.0 supports Android host broadcasting over Wi-Fi/hotspot and listener join links via QR/manual input.',
                ),
                Text(
                  'Internet signaling is optional and can be configured manually in Settings.',
                ),
                Text(
                  'Android is broadcaster-first. iOS is listener-first for this release.',
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  'Upcoming improvements',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('Advanced WebRTC optimization and transport tuning'),
                Text('Adaptive bitrate and sync correction enhancements'),
                Text('Improved microphone mixing and routing controls'),
                Text('Desktop broadcast support'),
              ],
            ),
          ),
          SizedBox(height: 12),
          SyncWaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Credits', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Created by R. Jha'),
                Text('Source code: https://github.com/rjrajujha/syncwave'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
