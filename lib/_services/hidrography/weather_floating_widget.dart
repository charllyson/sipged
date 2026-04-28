import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_utils/formatters/sipged_format_dates.dart';

enum AppState { notDownloaded, downloading, finishedDownloading }

class WeatherFloatingWidget extends StatefulWidget {
  const WeatherFloatingWidget({
    super.key,
    this.onClose,
    this.maxToasts = 8,
    this.onlyUpcomingHours = true,
    this.toastDuration = const Duration(seconds: 8),
  });

  final VoidCallback? onClose;
  final int maxToasts;
  final bool onlyUpcomingHours;
  final Duration toastDuration;

  @override
  State<WeatherFloatingWidget> createState() => _WeatherFloatingWidgetState();
}

class _WeatherFloatingWidgetState extends State<WeatherFloatingWidget> {
  final String apiKey = '12b6e28582eb9298577c734a31ba9f4f';

  late WeatherFactory ws;

  AppState state = AppState.notDownloaded;

  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();

    ws = WeatherFactory(
      apiKey,
      language: Language.PORTUGUESE,
    );

    _initLocationAndWeather();
  }

  Future<void> _initLocationAndWeather() async {
    if (!mounted) return;

    setState(() => state = AppState.downloading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _notifyError('Serviço de localização desativado.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _notifyError('Permissão de localização negada.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _notifyError('Permissão de localização negada permanentemente.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      _lat = pos.latitude;
      _lon = pos.longitude;

      await _fetchAndPublish();
    } catch (e) {
      _notifyError('Erro ao obter localização: $e');
    }
  }

  Future<void> _fetchAndPublish() async {
    if (_lat == null || _lon == null) {
      _notifyError('Localização indefinida.');
      return;
    }

    if (!mounted) return;

    setState(() => state = AppState.downloading);

    try {
      final forecasts = await ws.fiveDayForecastByLocation(_lat!, _lon!);

      if (!mounted) return;

      final now = DateTime.now();

      List<Weather> items = forecasts;

      if (widget.onlyUpcomingHours) {
        items = items.where((w) {
          return w.date == null || w.date!.isAfter(now);
        }).toList();
      }

      items.sort((a, b) {
        return (a.date ?? now).compareTo(b.date ?? now);
      });

      items = items.take(widget.maxToasts).toList();

      for (final w in items) {
        _publishToastFor(
          w,
          duration: widget.toastDuration,
        );
      }

      if (!mounted) return;

      setState(() => state = AppState.finishedDownloading);
    } catch (e) {
      _notifyError('Erro na previsão: $e');
    }
  }

  IconData _weatherIcon(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'rain':
        return Icons.cloudy_snowing;
      case 'clouds':
        return Icons.cloud;
      case 'clear':
        return Icons.wb_sunny;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.thunderstorm_outlined;
      case 'drizzle':
        return Icons.grain_outlined;
      case 'mist':
      case 'haze':
      case 'fog':
        return Icons.deblur_outlined;
      default:
        return Icons.thermostat;
    }
  }

  Color _accentColor(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'rain':
        return const Color(0xFF2979FF);
      case 'clouds':
        return const Color(0xFF90A4AE);
      case 'clear':
        return const Color(0xFFFFB300);
      case 'snow':
        return const Color(0xFF80DEEA);
      case 'thunderstorm':
        return const Color(0xFF7E57C2);
      case 'drizzle':
        return const Color(0xFF4DB6AC);
      case 'mist':
      case 'haze':
      case 'fog':
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _pt(String? main) {
    final m = (main ?? '').toLowerCase();

    switch (m) {
      case 'rain':
        return 'Chuva';
      case 'clouds':
        return 'Nuvens';
      case 'clear':
        return 'Céu limpo';
      case 'snow':
        return 'Neve';
      case 'thunderstorm':
        return 'Trovoadas';
      case 'drizzle':
        return 'Garoa';
      case 'mist':
        return 'Névoa';
      case 'smoke':
        return 'Fumaça';
      case 'haze':
        return 'Neblina';
      case 'dust':
        return 'Poeira';
      case 'fog':
        return 'Nevoeiro';
      case 'sand':
        return 'Areia';
      case 'ash':
        return 'Cinzas';
      case 'squall':
        return 'Rajadas';
      case 'tornado':
        return 'Tornado';
      default:
        return main ?? '';
    }
  }

  void _publishToastFor(
      Weather w, {
        required Duration duration,
      }) {
    if (!mounted) return;

    final accent = _accentColor(w.weatherMain);

    final temp = w.temperature?.celsius != null
        ? '${w.temperature!.celsius!.toStringAsFixed(1)} °C'
        : '--';

    final vento = w.windSpeed != null
        ? '${w.windSpeed!.toStringAsFixed(2)} m/s'
        : null;

    final subtitle = w.date != null
        ? 'Data: ${SipGedFormatDates.dateAndTimeHumanized(w.date!)}'
        : null;

    final id =
        'weather-${w.areaName ?? "local"}-${w.date?.millisecondsSinceEpoch ?? 0}';

    final details = vento == null
        ? 'Temperatura: $temp'
        : 'Temperatura: $temp • Vento: $vento';

    context.read<NotificationCubit>().show(
      NotificationData(
        id: id,
        type: NotificationType.info,
        accentColor: accent,
        duration: duration,
        icon: _weatherIcon(w.weatherMain),
        leadingLabel: w.areaName ?? 'Local',
        title: _pt(w.weatherMain),
        subtitle: subtitle,
        details: details,
        extra: {
          'module': 'weather',
          'areaName': w.areaName,
          'weatherMain': w.weatherMain,
          'temperatureCelsius': w.temperature?.celsius,
          'windSpeed': w.windSpeed,
          'date': w.date?.toIso8601String(),
        },
      ),
      saveInFirebase: false,
    );
  }

  void _notifyError(String msg) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        type: NotificationType.error,
        title: msg,
        icon: Icons.error_outline,
        leadingLabel: 'Clima',
        duration: const Duration(seconds: 6),
        extra: const <String, dynamic>{
          'module': 'weather',
        },
      ),
      saveInFirebase: false,
    );

    if (mounted) {
      setState(() => state = AppState.notDownloaded);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}