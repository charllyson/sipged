import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

/// Não desenha UI; busca previsão e publica toasts no NotificationCenter.
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
  AppState _state = AppState.NOT_DOWNLOADED;
  double? _lat, _lon;

  @override
  void initState() {
    super.initState();
    ws = WeatherFactory(apiKey, language: Language.PORTUGUESE);
    _initLocationAndWeather();
  }

  Future<void> _initLocationAndWeather() async {
    if (!mounted) return;
    setState(() => _state = AppState.DOWNLOADING);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _notifyError('Serviço de localização desativado.'); return; }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { _notifyError('Permissão de localização negada.'); return; }
      }
      if (permission == LocationPermission.deniedForever) { _notifyError('Permissão de localização negada permanentemente.'); return; }

      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude; _lon = pos.longitude;

      await _fetchAndPublish();
    } catch (e) { _notifyError('Erro ao obter localização: $e'); }
  }

  Future<void> _fetchAndPublish() async {
    if (_lat == null || _lon == null) { _notifyError('Localização indefinida.'); return; }
    if (!mounted) return;

    setState(() => _state = AppState.DOWNLOADING);
    try {
      final forecasts = await ws.fiveDayForecastByLocation(_lat!, _lon!);
      if (!mounted) return;

      final now = DateTime.now();
      List<Weather> items = forecasts;

      if (widget.onlyUpcomingHours) {
        items = items.where((w) => (w.date == null) || w.date!.isAfter(now)).toList();
      }
      items.sort((a, b) => (a.date ?? now).compareTo(b.date ?? now));
      items = items.take(widget.maxToasts).toList();

      for (final w in items) {
        _publishToastFor(w, duration: widget.toastDuration);
      }

      if (!mounted) return;
      setState(() => _state = AppState.FINISHED_DOWNLOADING);
    } catch (e) {
      _notifyError('Erro na previsão: $e');
    }
  }

  // ===== helpers de apresentação =====
  IconData _weatherIcon(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'rain': return Icons.cloudy_snowing;
      case 'clouds': return Icons.cloud;
      case 'clear': return Icons.wb_sunny;
      case 'snow': return Icons.ac_unit;
      case 'thunderstorm': return Icons.thunderstorm_outlined;
      case 'drizzle': return Icons.grain_outlined;
      case 'mist':
      case 'haze':
      case 'fog': return Icons.deblur_outlined;
      default: return Icons.thermostat;
    }
  }

  Color _accentColor(String? main) {
    switch ((main ?? '').toLowerCase()) {
      case 'rain': return const Color(0xFF2979FF);
      case 'clouds': return const Color(0xFF90A4AE);
      case 'clear': return const Color(0xFFFFB300);
      case 'snow': return const Color(0xFF80DEEA);
      case 'thunderstorm': return const Color(0xFF7E57C2);
      case 'drizzle': return const Color(0xFF4DB6AC);
      case 'mist':
      case 'haze':
      case 'fog': return const Color(0xFFB0BEC5);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _pt(String? main) {
    final m = (main ?? '').toLowerCase();
    switch (m) {
      case 'rain': return 'Chuva';
      case 'clouds': return 'Nuvens';
      case 'clear': return 'Céu limpo';
      case 'snow': return 'Neve';
      case 'thunderstorm': return 'Trovoadas';
      case 'drizzle': return 'Garoa';
      case 'mist': return 'Névoa';
      case 'smoke': return 'Fumaça';
      case 'haze': return 'Neblina';
      case 'dust': return 'Poeira';
      case 'fog': return 'Nevoeiro';
      case 'sand': return 'Areia';
      case 'ash': return 'Cinzas';
      case 'squall': return 'Rajadas';
      case 'tornado': return 'Tornado';
      default: return main ?? '';
    }
  }

  void _publishToastFor(Weather w, {required Duration duration}) {
    final accent = _accentColor(w.weatherMain);
    final temp = w.temperature?.celsius != null
        ? '${w.temperature!.celsius!.toStringAsFixed(1)} °C'
        : '--';
    final vento = w.windSpeed != null ? '${w.windSpeed!.toStringAsFixed(2)} m/s' : null;

    final subtitle = w.date != null ? Text('Data: ${dateAndTimeHumanized(w.date!)}') : null;
    final id = 'weather-${w.areaName ?? "local"}-${w.date?.millisecondsSinceEpoch ?? 0}';

    NotificationCenter.instance.show(
      AppNotification(
        id: id,
        type: AppNotificationType.info,
        accentColor: accent,
        duration: duration,
        leadingIcon: Icon(_weatherIcon(w.weatherMain), color: accent),
        leadingLabel: Text(w.areaName ?? 'Local'),
        title: Text(_pt(w.weatherMain), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle,
        details: Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.thermostat_outlined, size: 16),
              const SizedBox(width: 6),
              Text(temp, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            if (vento != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.air, size: 16),
                const SizedBox(width: 6),
                Text(vento, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
          ],
        ),
      ),
    );
  }

  void _notifyError(String msg) {
    NotificationCenter.instance.show(
      AppNotification(
        type: AppNotificationType.error,
        title: Text(msg),
        leadingIcon: const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
        leadingLabel: const Text('Clima'),
        duration: const Duration(seconds: 6),
      ),
    );
    if (mounted) setState(() => _state = AppState.NOT_DOWNLOADED);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
