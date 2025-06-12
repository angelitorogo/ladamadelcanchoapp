
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/nominatim_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/city_name/city_name_repository_provider.dart';

class CityNameNotifier extends StateNotifier<String> {
  final NominatimRepositoryImpl repository;


  CityNameNotifier(this.repository) : super('');

  Future<NominatimResponse> fetchCityName(LocationPoint point) async {
    try {
      final response = await repository.fecthNominatim(point);
      return response;
    } catch (e) {

      throw Exception('Error al obtener el municipio: ${e.toString()}');

    }
  }


  void reset() {
    state = '';
  }
}



final cityNameProvider = StateNotifierProvider<CityNameNotifier, String>((ref) {
  final repo = ref.read(cityNameRepositoryProvider);
  return CityNameNotifier(repo);
});
