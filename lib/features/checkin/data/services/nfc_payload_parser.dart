class NfcPayloadParseResult {
  const NfcPayloadParseResult({
    required this.code,
    required this.rawPayload,
    required this.source,
  });

  final String code;
  final String rawPayload;
  final String source;
}

class NfcPayloadParser {
  NfcPayloadParseResult parse(String rawPayload) {
    final raw = rawPayload.trim();
    if (raw.isEmpty) {
      throw const FormatException('NFC payload is empty');
    }

    final uri = Uri.tryParse(raw);
    final code = uri != null && uri.hasQuery
        ? uri.queryParameters['code']?.trim()
        : null;

    final normalized = (code == null || code.isEmpty) ? raw : code;
    return NfcPayloadParseResult(
      code: normalized,
      rawPayload: raw,
      source: code == null ? 'rawCode' : 'uri',
    );
  }
}
