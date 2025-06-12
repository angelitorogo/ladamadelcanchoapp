// To parse this JSON data, do
//
//     final weatherResponse = weatherResponseFromJson(jsonString);

import 'dart:convert';

WeatherResponse weatherResponseFromJson(String str) => WeatherResponse.fromJson(json.decode(str));

String weatherResponseToJson(WeatherResponse data) => json.encode(data.toJson());

class WeatherResponse {
    final double latitude;
    final double longitude;
    final double generationtimeMs;
    final int utcOffsetSeconds;
    final String timezone;
    final String timezoneAbbreviation;
    final double elevation;
    final DailyUnits dailyUnits;
    final Daily daily;

    WeatherResponse({
        required this.latitude,
        required this.longitude,
        required this.generationtimeMs,
        required this.utcOffsetSeconds,
        required this.timezone,
        required this.timezoneAbbreviation,
        required this.elevation,
        required this.dailyUnits,
        required this.daily,
    });

    factory WeatherResponse.fromJson(Map<String, dynamic> json) => WeatherResponse(
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        generationtimeMs: json["generationtime_ms"]?.toDouble(),
        utcOffsetSeconds: json["utc_offset_seconds"],
        timezone: json["timezone"],
        timezoneAbbreviation: json["timezone_abbreviation"],
        elevation: json["elevation"],
        dailyUnits: DailyUnits.fromJson(json["daily_units"]),
        daily: Daily.fromJson(json["daily"]),
    );

    Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
        "generationtime_ms": generationtimeMs,
        "utc_offset_seconds": utcOffsetSeconds,
        "timezone": timezone,
        "timezone_abbreviation": timezoneAbbreviation,
        "elevation": elevation,
        "daily_units": dailyUnits.toJson(),
        "daily": daily.toJson(),
    };
}

class Daily {
    final List<DateTime> time;
    final List<double> temperature2MMax;
    final List<double> temperature2MMin;
    final List<double> precipitationSum;
    final List<int> weathercode;

    Daily({
        required this.time,
        required this.temperature2MMax,
        required this.temperature2MMin,
        required this.precipitationSum,
        required this.weathercode,
    });

    factory Daily.fromJson(Map<String, dynamic> json) => Daily(
        time: List<DateTime>.from(json["time"].map((x) => DateTime.parse(x))),
        temperature2MMax: List<double>.from(json["temperature_2m_max"].map((x) => x?.toDouble())),
        temperature2MMin: List<double>.from(json["temperature_2m_min"].map((x) => x?.toDouble())),
        precipitationSum: List<double>.from(json["precipitation_sum"].map((x) => x?.toDouble())),
        weathercode: List<int>.from(json["weathercode"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "time": List<dynamic>.from(time.map((x) => "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}")),
        "temperature_2m_max": List<dynamic>.from(temperature2MMax.map((x) => x)),
        "temperature_2m_min": List<dynamic>.from(temperature2MMin.map((x) => x)),
        "precipitation_sum": List<dynamic>.from(precipitationSum.map((x) => x)),
        "weathercode": List<dynamic>.from(weathercode.map((x) => x)),
    };
}

class DailyUnits {
    final String time;
    final String temperature2MMax;
    final String temperature2MMin;
    final String precipitationSum;
    final String weathercode;

    DailyUnits({
        required this.time,
        required this.temperature2MMax,
        required this.temperature2MMin,
        required this.precipitationSum,
        required this.weathercode,
    });

    factory DailyUnits.fromJson(Map<String, dynamic> json) => DailyUnits(
        time: json["time"],
        temperature2MMax: json["temperature_2m_max"],
        temperature2MMin: json["temperature_2m_min"],
        precipitationSum: json["precipitation_sum"],
        weathercode: json["weathercode"],
    );

    Map<String, dynamic> toJson() => {
        "time": time,
        "temperature_2m_max": temperature2MMax,
        "temperature_2m_min": temperature2MMin,
        "precipitation_sum": precipitationSum,
        "weathercode": weathercode,
    };
}
