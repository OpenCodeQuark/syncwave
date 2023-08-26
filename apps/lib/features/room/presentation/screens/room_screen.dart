import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/primary_scaffold.dart';
import '../../../../shared/widgets/syncwave_card.dart';
import '../../../streaming/models/room_join_target.dart';
import '../../../streaming/providers/streaming_providers.dart';

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId, this.joinTarget});

  final String roomId;
  final RoomJoinTarget? joinTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? joinUrl;
    if (joinTarget != null) {
      try {
        joinUrl = ref.read(joinLinkServiceProvider).buildJoinUri(joinTarget!);
      } on FormatException {
        joinUrl = null;
      }
    }

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
                Text('Mode: ${joinTarget?.mode.label ?? 'Local'}'),
                Text('Host: ${joinTarget?.hostAddress ?? 'Unknown'}'),
                if (joinTarget?.roomPinProtected == true)
                  const Text('Room PIN protection: enabled')
                else
                  const Text('Room PIN protection: disabled'),
                const Text(
                  'Use browser listener to receive live audio stream in v1.0.0.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (joinUrl != null)
            SyncWaveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  const Text(
                    'Browser Listener Link',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SelectableText(joinUrl),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(joinUrl!);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open browser listener link.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: PhosphorIcon(PhosphorIcons.browser()),
                        label: const Text('Open in Browser'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: joinUrl!),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Join link copied')),
                          );
                        },
                        icon: PhosphorIcon(PhosphorIcons.copy()),
                        label: const Text('Copy Link'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(),
            icon: PhosphorIcon(PhosphorIcons.signOut()),
            label: const Text('Leave Session'),
          ),
        ],
      ),
    );
  }
}
