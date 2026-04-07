import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


// Helper: Convert weekday number to abbreviated string.
String getWeekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '';
  }
}

// Helper: Reorder forecast days so that the list starts on Monday.
List<dynamic> reorderForecast(List<dynamic> forecastList) {
  int mondayIndex = forecastList.indexWhere((dayForecast) {
    DateTime date = DateTime.parse(dayForecast['date']);
    return date.weekday == DateTime.monday;
  });
  if (mondayIndex == -1) {
    return forecastList;
  } else {
    return forecastList.sublist(mondayIndex) + forecastList.sublist(0, mondayIndex);
  }
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecast;
  bool isLoading = true;

  final String apiKey = "3b95c186c70a4aedaf680043251104";

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    // Use hardcoded coordinates for La Jolla (UCSD)
    final String queryLocation = "iata:SAN";

    final url = Uri.parse(
        "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$queryLocation&days=7&aqi=yes&alerts=no");
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      setState(() {
        currentWeather = data['current'];
        forecast = data['forecast']['forecastday'];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currentWeather == null || forecast == null) {
      return const Text('Failed to load weather');
    }

    Widget currentContainer = Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 80, 80, 80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Image.network(
            'https:${currentWeather!['condition']['icon']}',
            width: 48,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "La Jolla: ${currentWeather!['temp_f']}°F ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${currentWeather!['condition']['text']} • Feels like ${currentWeather!['feelslike_f']}°F",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                "UV: ${currentWeather!['uv']}",
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );

    List<dynamic> orderedForecast = reorderForecast(forecast!);

    Widget forecastRow = Row(
      children: orderedForecast.map((dayForecast) {
      DateTime date = DateTime.parse(dayForecast['date']);
      String dateStr = DateFormat('MMM d').format(date);
      String weekday = getWeekdayName(date.weekday);
      String maxTemp = "${dayForecast['day']['maxtemp_f']}°";
      String minTemp = "${dayForecast['day']['mintemp_f']}°";
      String iconUrl = "https:${dayForecast['day']['condition']['icon']}";
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(dateStr,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(weekday,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Image.network(iconUrl, width: 36, height: 36),
              const SizedBox(height: 4),
              Text(maxTemp,
                  style: const TextStyle(fontSize: 14, color: Colors.white)),
              Text(minTemp,
                  style: const TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
      );
    }).toList(),
  );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        currentContainer,
        const SizedBox(height: 16),
        forecastRow,
      ],
    );
  }
}
