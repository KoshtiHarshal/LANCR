// lib/core/utils/auth_errors.dart

/// Maps raw auth/network exceptions to short, user-friendly messages so we
/// never surface raw server/exception strings in the UI.
String friendlyAuthError(Object? error) {
  final msg = error?.toString().toLowerCase() ?? '';

  if (msg.contains('invalid login') ||
      msg.contains('invalid credentials') ||
      msg.contains('invalid email or password')) {
    return 'Incorrect email or password.';
  }
  if (msg.contains('already registered') ||
      msg.contains('already been registered') ||
      msg.contains('user already exists')) {
    return 'This email is already registered. Try signing in.';
  }
  if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (msg.contains('password') && msg.contains('at least')) {
    return 'Password is too short.';
  }
  if (msg.contains('rate limit') || msg.contains('too many')) {
    return 'Too many attempts. Please wait and try again.';
  }
  if (msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('failed host lookup') ||
      msg.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}
