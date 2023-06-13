class RoutePaths {
  const RoutePaths._();

  static const root = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const hostCreate = '/host/create';
  static const hostLive = '/host/live/:roomId';
  static const join = '/join';
  static const joinScan = '/join/scan';
  static const joinManual = '/join/manual';
  static const room = '/room/:roomId';
  static const settings = '/settings';
  static const debugNetwork = '/debug/network';
}
