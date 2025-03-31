import 'package:cookie_jar/cookie_jar.dart';

class GlobalCookieJar {
  static final CookieJar _jar = CookieJar();

  static CookieJar get instance => _jar;
}