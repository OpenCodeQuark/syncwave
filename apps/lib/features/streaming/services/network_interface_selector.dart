enum NetworkInterfaceKind { wifi, hotspot, mobile, other }

class NetworkAddressDescriptor {
  const NetworkAddressDescriptor({
    required this.interfaceName,
    required this.address,
  });

  final String interfaceName;
  final String address;
}

class LocalNetworkCandidate {
  const LocalNetworkCandidate({
    required this.interfaceName,
    required this.address,
    required this.kind,
  });

  final String interfaceName;
  final String address;
  final NetworkInterfaceKind kind;
}

class NetworkInterfaceSelector {
  List<LocalNetworkCandidate> buildCandidates(
    List<NetworkAddressDescriptor> addresses,
  ) {
    final candidates = <LocalNetworkCandidate>[];

    for (final descriptor in addresses) {
      if (!_isValidPrivateIpv4(descriptor.address)) {
        continue;
      }

      final kind = _classifyInterface(descriptor.interfaceName);
      candidates.add(
        LocalNetworkCandidate(
          interfaceName: descriptor.interfaceName,
          address: descriptor.address,
          kind: kind,
        ),
      );
    }

    return candidates;
  }

  LocalNetworkCandidate? selectPreferredCandidate(
    List<LocalNetworkCandidate> candidates,
  ) {
    LocalNetworkCandidate? pick(NetworkInterfaceKind kind) {
      for (final candidate in candidates) {
        if (candidate.kind == kind) {
          return candidate;
        }
      }
      return null;
    }

    return pick(NetworkInterfaceKind.wifi) ??
        pick(NetworkInterfaceKind.hotspot) ??
        pick(NetworkInterfaceKind.other);
  }

  bool isMobileOnly(List<LocalNetworkCandidate> candidates) {
    if (candidates.isEmpty) {
      return false;
    }

    for (final candidate in candidates) {
      if (candidate.kind != NetworkInterfaceKind.mobile) {
        return false;
      }
    }

    return true;
  }

  NetworkInterfaceKind _classifyInterface(String name) {
    final normalized = name.toLowerCase();

    if (_containsAny(normalized, const [
      'wlan',
      'wifi',
      'wi-fi',
      'en0',
      'wl',
    ])) {
      return NetworkInterfaceKind.wifi;
    }

    if (_containsAny(normalized, const ['hotspot', 'tether', 'ap', 'rndis'])) {
      return NetworkInterfaceKind.hotspot;
    }

    if (_containsAny(normalized, const [
      'rmnet',
      'ccmni',
      'pdp',
      'wwan',
      'cell',
    ])) {
      return NetworkInterfaceKind.mobile;
    }

    return NetworkInterfaceKind.other;
  }

  bool _containsAny(String source, List<String> patterns) {
    for (final pattern in patterns) {
      if (source.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  bool _isValidPrivateIpv4(String rawIp) {
    final parts = rawIp.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    final first = octets[0];
    final second = octets[1];

    if (first == 127) {
      return false;
    }

    if (first == 169 && second == 254) {
      return false;
    }

    if (first == 0 || first >= 224) {
      return false;
    }

    if (first == 10) {
      return true;
    }

    if (first == 172 && second >= 16 && second <= 31) {
      return true;
    }

    if (first == 192 && second == 168) {
      return true;
    }

    return false;
  }
}
