import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_paths.dart';
import '../features/about/presentation/screens/about_screen.dart';
import '../features/debug/presentation/screens/network_debug_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/host/presentation/screens/host_create_screen.dart';
import '../features/host/presentation/screens/host_live_room_screen.dart';
import '../features/join/presentation/screens/join_manual_screen.dart';
import '../features/join/presentation/screens/join_scan_screen.dart';
import '../features/join/presentation/screens/join_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/room/presentation/screens/room_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/streaming/models/hosted_session.dart';
import '../features/streaming/models/room_join_target.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.root,
    routes: [
      GoRoute(
        path: RoutePaths.root,
        name: 'root',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.hostCreate,
        name: 'hostCreate',
        builder: (context, state) => const HostCreateScreen(),
      ),
      GoRoute(
        path: RoutePaths.hostLive,
        name: 'hostLive',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? 'unknown';
          final hostedSession = state.extra is HostedSession
              ? state.extra as HostedSession
              : null;
          return HostLiveRoomScreen(
            roomId: roomId,
            hostedSession: hostedSession,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.join,
        name: 'join',
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: RoutePaths.joinScan,
        name: 'joinScan',
        builder: (context, state) => const JoinScanScreen(),
      ),
      GoRoute(
        path: RoutePaths.joinManual,
        name: 'joinManual',
        builder: (context, state) => const JoinManualScreen(),
      ),
      GoRoute(
        path: RoutePaths.room,
        name: 'room',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? 'unknown';
          final joinTarget = state.extra is RoomJoinTarget
              ? state.extra as RoomJoinTarget
              : null;
          return RoomScreen(roomId: roomId, joinTarget: joinTarget);
        },
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RoutePaths.debugNetwork,
        name: 'debugNetwork',
        builder: (context, state) => const NetworkDebugScreen(),
      ),
    ],
  );
});
