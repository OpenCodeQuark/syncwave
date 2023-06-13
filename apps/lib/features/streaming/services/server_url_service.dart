class ServerUrlService {
  static const _supportedSchemes = {'ws', 'wss', 'http', 'https'};

  bool isValidServerUrl(String value) {
    try {
      normalize(value);
      return true;
    } on FormatException {
      return false;
    }
  }

  String normalize(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Server URL is required.');
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
      throw const FormatException('Server URL must include scheme and host.');
    }

    final normalizedScheme = _normalizeScheme(parsed.scheme);
    var path = parsed.path;
    if (path.isEmpty || path == '/') {
      path = '/ws';
    }

    final normalized = Uri(
      scheme: normalizedScheme,
      userInfo: parsed.userInfo.isEmpty ? null : parsed.userInfo,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: path,
      query: parsed.hasQuery ? parsed.query : null,
      fragment: parsed.hasFragment ? parsed.fragment : null,
    );

    return normalized.toString();
  }

  String _normalizeScheme(String scheme) {
    final lower = scheme.toLowerCase();
    if (!_supportedSchemes.contains(lower)) {
      throw const FormatException('Unsupported URL scheme.');
    }

    if (lower == 'https') {
      return 'wss';
    }

    if (lower == 'http') {
      return 'ws';
    }

    return lower;
  }
}
