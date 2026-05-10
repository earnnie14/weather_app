import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../model/weather.dart';
import '../config.dart';

class WeatherService {
  // Get weather by city name
  Future<Weather> getWeatherByCity(String city) async {
    final url = Uri.parse(
      '${Config.baseUrl}/weather?q=$city&appid=${Config.apiKey}&units=metric',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('City not found: $city');
    }
  }

  // Get weather by GPS location
  Future<Weather> getWeatherByLocation() async {
    final position = await _getCurrentPosition();
    final url = Uri.parse(
      '${Config.baseUrl}/weather?lat=${position.latitude}&lon=${position.longitude}&appid=${Config.apiKey}&units=metric',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unable to fetch weather data');
    }
  }

  // Get 7-day forecast by city name
  Future<List<DailyForecast>> getForecast(String city) async {
    final url = Uri.parse(
      '${Config.baseUrl}/forecast?q=$city&appid=${Config.apiKey}&units=metric',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['list'];
      final Map<String, DailyForecast> dailyMap = {};
      for (var item in items) {
        final date = item['dt_txt'].toString().split(' ')[0];
        final time = item['dt_txt'].toString().split(' ')[1];
        if (time == '12:00:00' && !dailyMap.containsKey(date)) {
          dailyMap[date] = DailyForecast(
            date: date,
            tempMin: (item['main']['temp_min'] as num).toDouble(),
            tempMax: (item['main']['temp_max'] as num).toDouble(),
            icon: item['weather'][0]['icon'],
            description: item['weather'][0]['description'],
          );
        }
      }
      return dailyMap.values.toList();
    } else {
      throw Exception('Unable to fetch forecast');
    }
  }

  // Request permission and get GPS position
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable in Settings',
      );
    }
    return await Geolocator.getCurrentPosition();
  }
}
