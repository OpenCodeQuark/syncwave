import 'package:flutter_test/flutter_test.dart';
import 'package:syncwave/features/streaming/services/network_interface_selector.dart';

void main() {
  group('NetworkInterfaceSelector', () {
    final selector = NetworkInterfaceSelector();

    test('prefers Wi-Fi over hotspot and other interfaces', () {
      final candidates = selector.buildCandidates(const [
        NetworkAddressDescriptor(interfaceName: 'ap0', address: '192.168.43.1'),
        NetworkAddressDescriptor(
          interfaceName: 'wlan0',
          address: '192.168.1.12',
        ),
        NetworkAddressDescriptor(interfaceName: 'eth0', address: '10.0.0.8'),
      ]);

      final selected = selector.selectPreferredCandidate(candidates);
      expect(selected, isNotNull);
      expect(selected!.interfaceName, 'wlan0');
    });

    test('rejects loopback and link-local addresses', () {
      final candidates = selector.buildCandidates(const [
        NetworkAddressDescriptor(interfaceName: 'lo', address: '127.0.0.1'),
        NetworkAddressDescriptor(interfaceName: 'en0', address: '169.254.10.2'),
      ]);

      expect(candidates, isEmpty);
    });

    test('detects mobile-only candidate list', () {
      final candidates = selector.buildCandidates(const [
        NetworkAddressDescriptor(
          interfaceName: 'rmnet_data0',
          address: '10.111.0.4',
        ),
      ]);

      expect(selector.isMobileOnly(candidates), isTrue);
      expect(selector.selectPreferredCandidate(candidates), isNull);
    });
  });
}
