

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/auth_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepositoryImpl>( (ref) {
  return AuthRepositoryImpl(AuthDatasourceImpl());
});