import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';

Future<void> refreshDioInterceptors(Dio dio) async {
  final jar = await GlobalCookieJar.instance;
  dio.interceptors.clear();
  dio.interceptors.add(CookieManager(jar));
}
