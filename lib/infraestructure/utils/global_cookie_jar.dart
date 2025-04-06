/*
import 'package:cookie_jar/cookie_jar.dart';

class GlobalCookieJar {
  static final CookieJar _jar = CookieJar();

  static CookieJar get instance => _jar;
}
*/

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class GlobalCookieJar {
  static PersistCookieJar? _jar;

  static Future<CookieJar> get instance async {
    if (_jar == null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      _jar = PersistCookieJar(
        ignoreExpires: false,
        storage: FileStorage('${appDocDir.path}/.cookies/'),
      );
    }
    return _jar!;
  }
}
