class OpenAlexException implements Exception {
  const OpenAlexException(this.message);

  final String message;

  @override
  String toString() => message;
}
