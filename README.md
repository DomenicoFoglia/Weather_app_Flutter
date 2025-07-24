# Weather App Flutter

Una semplice applicazione meteo sviluppata in Flutter che mostra le previsioni del tempo attuali e future utilizzando l'API di OpenWeatherMap.

---

## Caratteristiche

- Visualizzazione della temperatura attuale, condizioni meteo e informazioni aggiuntive (umidità, pressione, velocità del vento)
- Ricerca città manuale
- Ottenimento della posizione attuale tramite geolocalizzazione
- Previsioni orarie con icone meteo
- Supporto tema chiaro/scuro (toggle tema)

---


## Tecnologie usate

- Flutter
- Dart
- OpenWeatherMap API
- Geolocator per la posizione
- Package intl per la formattazione delle date
- Weather Icons per le icone meteo

---

## Come usare

1. Clona il repository:
   ```bash
   git clone https://github.com/tuo-username/weather_app.git
   cd weather_app

2. Installa le dipendenze:
    flutter pub get

3. Inserisci la tua API key di OpenWeatherMap in stuff.dart (o dove la gestisci):
    const String openWeatherAPIKey = 'LA_TUA_API_KEY';

4. Avvia l'app:
    flutter run