


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/weather_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/weather_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/weather/weather_repository_provider.dart';

enum WeatherStatus { idle, loading, success, error }

class WeatherState {
  final WeatherStatus status;
  final String? message;

  const WeatherState({
    this.status = WeatherStatus.idle,
    this.message,
  });

  WeatherState copyWith({
    WeatherStatus? status,
    String? message,
  }) {
    return WeatherState(
      status: status ?? this.status,
      message: message,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherRepositoryImpl repository;


  WeatherNotifier(this.repository) : super(const WeatherState());

  Future<WeatherResponse?> fetchWeatherData(LocationPoint point) async {
    state = state.copyWith(status: WeatherStatus.loading);
    try {
      final WeatherResponse response = await repository.fetchDailyForecast(point);
      state = state.copyWith(status: WeatherStatus.success);
      return response;
    } catch (e) {
      state = state.copyWith(
        status: WeatherStatus.error,
        message: e.toString(),
      );
      return null;
    }
  }


  void reset() {
    state = const WeatherState();
  }
}



final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final repo = ref.read(weatherRepositoryProvider);
  return WeatherNotifier(repo);
});
