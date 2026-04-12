class WeatherData {
  final double temp;
  final String condition;

  WeatherData({required this.temp, required this.condition});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'],
    );
  }
}