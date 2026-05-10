import 'package:flutter/material.dart';
import '../model/weather.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  Weather? _weather;
  bool _isLoading = false;
  String? _errorMessage;
  List<DailyForecast> _forecast = [];

  @override
  void initState() {
    super.initState();
    _loadWeatherByLocation();
  }

  Future<void> _loadWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _weatherService.getWeatherByLocation();
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeatherByCity(String city) async {
    if (city.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _weatherService.getWeatherByCity(city);
      final forecast = await _weatherService.getForecast(city);
      setState(() {
        _weather = weather;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'City not found';
        _isLoading = false;
      });
    }
  }

  List<Color> _getBackgroundColors(String icon) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;

    if (isNight) {
      return [
        const Color(0xFF0d0d1a),
        const Color(0xFF1a1a2e),
        const Color(0xFF16213e),
      ];
    }
    if (icon.startsWith('01')) {
      return [
        const Color(0xFF1a6ba0),
        const Color(0xFF1e90c8),
        const Color(0xFF87CEEB),
      ];
    }
    if (icon.startsWith('02') ||
        icon.startsWith('03') ||
        icon.startsWith('04')) {
      return [
        const Color(0xFF4a5568),
        const Color(0xFF2d3748),
        const Color(0xFF1a202c),
      ];
    }
    if (icon.startsWith('09') ||
        icon.startsWith('10') ||
        icon.startsWith('11')) {
      return [
        const Color(0xFF1a202c),
        const Color(0xFF2d3748),
        const Color(0xFF2c5282),
      ];
    }
    if (icon.startsWith('13')) {
      return [
        const Color(0xFF90cdf4),
        const Color(0xFF63b3ed),
        const Color(0xFF4299e1),
      ];
    }
    return [
      const Color(0xFF1a1a2e),
      const Color(0xFF16213e),
      const Color(0xFF0f3460),
    ];
  }

  String _getWeatherEmoji(String icon) {
    if (icon.startsWith('01')) return '☀️';
    if (icon.startsWith('02')) return '⛅';
    if (icon.startsWith('03') || icon.startsWith('04')) return '☁️';
    if (icon.startsWith('09') || icon.startsWith('10')) return '🌧️';
    if (icon.startsWith('11')) return '⛈️';
    if (icon.startsWith('13')) return '❄️';
    if (icon.startsWith('50')) return '🌫️';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _weather != null
                ? _getBackgroundColors(_weather!.icon)
                : [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _errorMessage != null
                      ? _buildError()
                      : _weather != null
                      ? _buildWeatherContent()
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.my_location,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: _loadWeatherByLocation,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        onSubmitted: _loadWeatherByCity,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWeatherByLocation,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final w = _weather!;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // City name
          Text(
            '${w.cityName}, ${w.country}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Weather emoji
          Text(_getWeatherEmoji(w.icon), style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          // Temperature
          Text(
            '${w.temperature.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w200,
            ),
          ),
          // Description
          Text(
            w.description.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feels like ${w.feelsLike.round()}°C',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          // Info cards
          _buildInfoCards(w), const SizedBox(height: 20),
          if (_forecast.isNotEmpty) _buildForecast(),
        ],
      ),
    );
  }

  Widget _buildInfoCards(Weather w) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.water_drop, '${w.humidity}%', 'Humidity'),
          _buildInfoItem(Icons.air, '${w.windSpeed} m/s', 'Wind'),
          _buildInfoItem(
            Icons.visibility,
            '${(w.visibility / 1000).toStringAsFixed(1)} km',
            'Visibility',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._forecast.map((f) => _buildForecastRow(f)),
        ],
      ),
    );
  }

  Widget _buildForecastRow(DailyForecast f) {
    final date = DateTime.parse(f.date);
    final dayName = DateFormat('EEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              dayName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          Text(_getWeatherEmoji(f.icon), style: const TextStyle(fontSize: 20)),
          Text(
            '${f.tempMin.round()}° / ${f.tempMax.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
