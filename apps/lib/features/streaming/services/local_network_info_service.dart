import 'dart:io';

import '../../../core/errors/app_exception.dart';
import 'network_interface_selector.dart';

class LocalNetworkInfo {
  const LocalNetworkInfo({
    required this.address,
    required this.interfaceName,
    required this.kind,
  });

  final String address;
  final String interfaceName;
  final NetworkInterfaceKind kind;
}

class LocalNetworkInfoService {
  LocalNetworkInfoService({NetworkInterfaceSelector? selector})
    : _selector = selector ?? NetworkInterfaceSelector();

  final NetworkInterfaceSelector _selector;

  Future<LocalNetworkInfo> selectBestLocalNetwork() async {
    List<NetworkInterface> rawInterfaces;
    try {
      rawInterfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
    } catch (_) {
      throw AppException(
        'Connect to Wi-Fi or enable hotspot to start a local broadcast.',
        code: 'local_network_unavailable',
      );
    }

    final descriptors = <NetworkAddressDescriptor>[];
    for (final interface in rawInterfaces) {
      for (final address in interface.addresses) {
        descriptors.add(
          NetworkAddressDescriptor(
            interfaceName: interface.name,
            address: address.address,
          ),
        );
      }
    }

    final candidates = _selector.buildCandidates(descriptors);
    final selected = _selector.selectPreferredCandidate(candidates);

    if (selected == null || _selector.isMobileOnly(candidates)) {
      throw AppException(
        'Connect to Wi-Fi or enable hotspot to start a local broadcast.',
        code: 'local_network_unavailable',
      );
    }

    return LocalNetworkInfo(
      address: selected.address,
      interfaceName: selected.interfaceName,
      kind: selected.kind,
    );
  }
}
