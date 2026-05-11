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
      // กลางคืน — น้ำเงินเข้มมาก
      return [
        const Color(0xFF0a0a1a),
        const Color(0xFF0d0d2b),
        const Color(0xFF1a1a3e),
      ];
    }
    if (icon.startsWith('01')) {
      // แดดจัด — ฟ้าสดใส
      return [
        const Color.fromARGB(255, 255, 253, 112),
        const Color(0xFF0099ff),
        const Color(0xFF66ccff),
      ];
    }
    if (icon.startsWith('02') ||
        icon.startsWith('03') ||
        icon.startsWith('04')) {
      // เมฆมาก — เทาอมฟ้า
      return [
        const Color(0xFF5a6a7a),
        const Color(0xFF7a8a9a),
        const Color(0xFF9aaaba),
      ];
    }
    if (icon.startsWith('09') ||
        icon.startsWith('10') ||
        icon.startsWith('11')) {
      // ฝนตก/พายุ — เทาเข้มอมม่วง
      return [
        const Color(0xFF1a1a2e),
        const Color(0xFF2d2d4e),
        const Color(0xFF1e3a5f),
      ];
    }
    if (icon.startsWith('13')) {
      // หิมะ — ขาวอมฟ้า
      return [
        const Color(0xFFb0d4f1),
        const Color(0xFFd6eaf8),
        const Color(0xFFebf5fb),
      ];
    }
    if (icon.startsWith('50')) {
      // หมอก — เทาอ่อน
      return [
        const Color(0xFF8a9ba8),
        const Color(0xFFa8b8c5),
        const Color(0xFFc5d5e2),
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
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        key: ValueKey(_weather?.icon ?? 'default'),
        builder: (context, value, child) {
          return Container(
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
            child: child,
          );
        },
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
          _buildInfoCards(w), _buildSunInfo(w), const SizedBox(height: 20),
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

  Widget _buildSunInfo(Weather w) {
    final sunrise = DateTime.fromMillisecondsSinceEpoch(w.sunrise * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(w.sunset * 1000);
    final format = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.arrow_upward, '${w.tempMax.round()}°', 'High'),
          _buildInfoItem(Icons.arrow_downward, '${w.tempMin.round()}°', 'Low'),
          _buildInfoItem(Icons.wb_sunny, format.format(sunrise), 'Sunrise'),
          _buildInfoItem(Icons.nights_stay, format.format(sunset), 'Sunset'),
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
