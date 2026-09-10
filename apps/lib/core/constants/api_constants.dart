class ApiConstants {
  static const String baseUrl = "http://192.168.215.100:3000/api";
  // ✅ Change from /auth to /users to match your backend model name
  static const String login = "/users/login";
  static const String register = "/users/register";

  static const String history = "/scans/history";
  static const String weather = "/weather";
  static const String predict = "/users/predict";
}
