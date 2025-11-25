import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://ai-companion-nyvp.onrender.com";
    } else {
      return "http://localhost:3000";
    }
  }
}
