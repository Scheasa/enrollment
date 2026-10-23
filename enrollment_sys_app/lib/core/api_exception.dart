/// Every API failure becomes one of these, with a message safe to show the user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  /// Builds an exception from a Laravel error body:
  ///   { "success": false, "message": "..." }
  ///   { "message": "...", "errors": { "email": ["The email has already been taken."] } }
  factory ApiException.fromResponse(int status, Map<String, dynamic> body) {
    String message = (body['message'] ?? 'Something went wrong (HTTP $status).')
        .toString();

    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString(); // show the first field error
      }
    }

    return ApiException(message, statusCode: status);
  }

  @override
  String toString() => message;
}
