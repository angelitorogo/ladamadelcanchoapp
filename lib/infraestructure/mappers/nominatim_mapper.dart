// To parse this JSON data, do
//
//     final nominatimResponse = nominatimResponseFromJson(jsonString);

import 'dart:convert';

NominatimResponse nominatimResponseFromJson(String str) => NominatimResponse.fromJson(json.decode(str));

String nominatimResponseToJson(NominatimResponse data) => json.encode(data.toJson());

class NominatimResponse {
    final int placeId;
    final String licence;
    final String osmType;
    final int osmId;
    final String lat;
    final String lon;
    final String nominatimResponseClass;
    final String type;
    final int placeRank;
    final double importance;
    final String addresstype;
    final String name;
    final String displayName;
    final Address address;
    final List<String> boundingbox;

    NominatimResponse({
        required this.placeId,
        required this.licence,
        required this.osmType,
        required this.osmId,
        required this.lat,
        required this.lon,
        required this.nominatimResponseClass,
        required this.type,
        required this.placeRank,
        required this.importance,
        required this.addresstype,
        required this.name,
        required this.displayName,
        required this.address,
        required this.boundingbox,
    });

    factory NominatimResponse.fromJson(Map<String, dynamic> json) => NominatimResponse(
        placeId: json["place_id"] ?? '',
        licence: json["licence"] ?? '',
        osmType: json["osm_type"] ?? '',
        osmId: json["osm_id"] ?? '',
        lat: json["lat"] ?? '',
        lon: json["lon"] ?? '',
        nominatimResponseClass: json["class"] ?? '',
        type: json["type"] ?? '',
        placeRank: json["place_rank"] ?? '',
        importance: json["importance"]?.toDouble() ?? 0.0,
        addresstype: json["addresstype"] ?? '',
        name: json["name"] ?? '',
        displayName: json["display_name"] ?? '',
        address: Address.fromJson(json["address"]),
        boundingbox: List<String>.from(json["boundingbox"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "place_id": placeId,
        "licence": licence,
        "osm_type": osmType,
        "osm_id": osmId,
        "lat": lat,
        "lon": lon,
        "class": nominatimResponseClass,
        "type": type,
        "place_rank": placeRank,
        "importance": importance,
        "addresstype": addresstype,
        "name": name,
        "display_name": displayName,
        "address": address.toJson(),
        "boundingbox": List<dynamic>.from(boundingbox.map((x) => x)),
    };
}

class Address {
    final String tourism;
    final String road;
    final String neighbourhood;
    final String quarter;
    final String cityDistrict;
    final String city;
    final String state;
    final String iso31662Lvl4;
    final String postcode;
    final String country;
    final String countryCode;

    Address({
        required this.tourism,
        required this.road,
        required this.neighbourhood,
        required this.quarter,
        required this.cityDistrict,
        required this.city,
        required this.state,
        required this.iso31662Lvl4,
        required this.postcode,
        required this.country,
        required this.countryCode,
    });

    factory Address.fromJson(Map<String, dynamic> json) => Address(
        tourism: json["tourism"] ?? '',
        road: json["road"] ?? '',
        neighbourhood: json["neighbourhood"] ?? '',
        quarter: json["quarter"] ?? '',
        cityDistrict: json["city_district"] ?? '',
        city: json["city"] ?? '',
        state: json["state"] ?? '',
        iso31662Lvl4: json["ISO3166-2-lvl4"] ?? '',
        postcode: json["postcode"] ?? '',
        country: json["country"] ?? '',
        countryCode: json["country_code"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "tourism": tourism,
        "road": road,
        "neighbourhood": neighbourhood,
        "quarter": quarter,
        "city_district": cityDistrict,
        "city": city,
        "state": state,
        "ISO3166-2-lvl4": iso31662Lvl4,
        "postcode": postcode,
        "country": country,
        "country_code": countryCode,
    };
}
