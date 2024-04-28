class CurrentCityData {
  String? currentCity;
  num? lon;
  num? lat;
  int? id;
  String? description;
  String? icon;
  num? temp;
  num? maxTemp;
  num? minTemp;
  num? windSpeed;
  int? sunrise;
  int? sunset;
  int? humidity;
  CurrentCityData(
    this.currentCity,
    this.lon,
    this.lat,
    this.id,
    this.description,
    this.icon,
    this.temp,
    this.maxTemp,
    this.minTemp,
    this.windSpeed,
    this.sunrise,
    this.sunset,
    this.humidity,
  );
}
