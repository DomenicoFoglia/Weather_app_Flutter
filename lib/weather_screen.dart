import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/additional_information.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/stuff.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class WeatherScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const WeatherScreen({super.key, required this.onToggleTheme});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // Funzione per convertire le condizioni in icone
  Widget getWeatherIcon(String condition) {
    switch (condition) {
      case 'Clear':
        return Icon(Icons.wb_sunny, color: Colors.amber);
      case 'Clouds':
        return Icon(Icons.cloud);
      case 'Rain':
        return Icon(WeatherIcons.rain, color: Colors.lightBlueAccent);
      case 'Snow':
        return Icon(WeatherIcons.snow);
      case 'Thunderstorm':
        return Icon(WeatherIcons.thunderstorm, color: Colors.blueGrey);
      case 'Drizzle':
        return Icon(WeatherIcons.sprinkle);
      default:
        return Icon(WeatherIcons.day_fog);
    }
  }

  //API

  //Funzione geolocalizzazione
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    //Verrifica se il servizio di localizzazione e' attivo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Servizio di localizzazione non attivo');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permessi di localizzazione negati');
      }
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  late Future<dynamic> _weatherFuture;
  String? cityName = 'Catanzaro';
  double? latitude;
  double? longitude;
  TextEditingController cityController = TextEditingController(
    text: 'Catanzaro',
  );

  Future getCurrentWeather({String? city, double? lat, double? lon}) async {
    try {
      Uri url;

      if (lat != null && lon != null) {
        url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$openWeatherAPIKey&units=metric',
        );
      } else if (city != null && city.isNotEmpty) {
        url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$openWeatherAPIKey&units=metric',
        );
      } else {
        throw 'Nessuna città o coordinate fornite';
      }

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['cod'] != "200") {
        throw "Errore API: ${data['message']}";
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _weatherFuture = getCurrentWeather(city: cityName);
  }

  void _fetchWeatherByCurrentLocation() async {
    try {
      final pos = await _determinePosition();

      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
        cityName = null; // resetto cityName per usare lat/lon
        cityController.text = ''; // pulisco input
        _weatherFuture = getCurrentWeather(lat: latitude, lon: longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore localizzazione: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            tooltip: 'Usa posizione attuale',
            onPressed: _fetchWeatherByCurrentLocation,
          ),

          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                if (latitude != null && longitude != null) {
                  _weatherFuture = getCurrentWeather(
                    lat: latitude,
                    lon: longitude,
                  );
                } else {
                  _weatherFuture = getCurrentWeather(city: cityName);
                }
              });
            },
          ),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _weatherFuture,
        builder: (context, asyncSnapshot) {
          //Cerchio di caricamento
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(),
            ); //adaptive serve a faar capire a flutter che, in base al sistema operativo in cui si trova, deve far vedere un cerchio di caricamento diverso
          }

          if (asyncSnapshot.hasError) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              hintText: 'Inserisci una città',
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final input = cityController.text.trim();
                            if (input.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Inserisci il nome di una città',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              cityName = input;
                              latitude = null;
                              longitude = null;
                              _weatherFuture = getCurrentWeather(
                                city: cityName,
                              );
                            });
                          },
                          child: const Text('Cerca'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Città non trovata. Riprova con un nome valido.',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchWeatherByCurrentLocation,
                      icon: Icon(Icons.my_location),
                      label: Text('Usa la mia posizione'),
                    ),
                  ],
                ),
              ),
            );
          }

          //Caricamento temperatura
          //Equivale a if(asyncSnapshot.data != null)
          final data = asyncSnapshot.data!;
          //Salvo la temperatura e la converto in Celsius
          final currentTemperature = data['list'][0]['main']['temp'];
          //Gestione del testo (Rain, Sunny ecc..) in base al clima
          final currentSky = data['list'][0]['weather'][0]['main'];
          //Gestione Informazioni addizionali
          final currentPressure = data['list'][0]['main']['pressure'];
          final windSpeed = (data['list'][0]['wind']['speed'] * 3.6)
              .toStringAsFixed(2);
          final currentHumidity = data['list'][0]['main']['humidity'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, //Questo ci permette di scegliere come verranno posizionati tutti i figli (altrimenti avremmo dovuto usare Align per ogni widget che volevamo allineare)
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            hintText: 'Inserisci una città',
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final input = cityController.text.trim();
                          if (input.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Inserisci il nome di una città'),
                              ),
                            );
                            return; // esci senza aggiornare
                          }
                          setState(() {
                            cityName = input;
                            latitude = null;
                            longitude = null;
                            _weatherFuture = getCurrentWeather(city: cityName);
                          });
                        },
                        child: const Text('Cerca'),
                      ),
                    ],
                  ),
                  //main card
                  SizedBox(
                    // Ho messo SizedBox altrimenti il solo widget Card occupa oslo lo spazio necessario a contenere i suoi figli
                    width: double.infinity,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '${currentTemperature.toStringAsFixed(1)} °C',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                currentSky == 'Clear'
                                    ? Icon(
                                        Icons.wb_sunny,
                                        size: 64,
                                        color: Colors.amber,
                                      )
                                    : currentSky == 'Clouds'
                                    ? Icon(Icons.cloud, size: 64)
                                    : BoxedIcon(
                                        WeatherIcons.rain,
                                        size: 64,
                                        color: Colors.blue,
                                      ),
                                const SizedBox(height: 16),
                                Text(
                                  currentSky,
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Serve a dare uno spazio tra i widget
                  // weather forecast cards
                  const Text(
                    'Previsione prossime ore',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: 39,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index + 1];
                        final hourlySky = hourlyForecast['weather'][0]['main'];
                        final time = DateTime.parse(hourlyForecast['dt_txt']);
                        return HourlyForecastItem(
                          time: DateFormat.Hm().format(time),
                          temperature: (hourlyForecast['main']['temp'])
                              .toStringAsFixed(1),
                          icon: getWeatherIcon(hourlySky),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Altre informazioni',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // informazioni addizionali
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInformation(
                        icon: Icons.water_drop,
                        label: 'Umidità',
                        value: currentHumidity.toString(),
                      ),
                      AdditionalInformation(
                        icon: Icons.air,
                        label: 'Vento',
                        value: '$windSpeed km/h',
                      ),
                      AdditionalInformation(
                        icon: Icons.beach_access,
                        label: 'Pressione',
                        value: currentPressure.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse(
                        'https://github.com/DomenicoFoglia',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        throw 'Impossibile aprire il link';
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      color: Colors.grey[800],
                      child: Text(
                        "Domenico Foglia 2025 • GitHub",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
