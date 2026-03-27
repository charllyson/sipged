// lib/_services/map/map_box/mapbox_html_builder.dart
import 'dart:convert';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';

String buildMapboxHtml(
    MapboxMapConfig config, {
      required String viewId,
    }) {
  final cfgJson = jsonEncode(config.toJsonForHtml());

  final initialMarkersJson = jsonEncode(
    config.markers.map((m) => m.toJson()).toList(),
  );

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
  <title>Mapbox 3D in Flutter</title>

  <script src="https://api.mapbox.com/mapbox-gl-js/v3.4.0/mapbox-gl.js"></script>
  <link href="https://api.mapbox.com/mapbox-gl-js/v3.4.0/mapbox-gl.css" rel="stylesheet"/>

  <style>
    html, body, #map {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    #map {
      position: absolute;
      top: 0;
      left: 0;
    }
  </style>
</head>

<body>
  <div id="map"></div>

  <script>
    const cfg = $cfgJson;
    const SIGED_VIEW_ID = '$viewId';

    mapboxgl.accessToken = cfg.accessToken;

    let map;
    let flutterMarkers = [];
    let currentMarkersData = [];

    function clearMarkers() {
      flutterMarkers.forEach(m => m.remove());
      flutterMarkers = [];
    }

    function notifyMarkerClick(payload) {
      // Caso Web (iframe → Flutter)
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(payload, '*');
      }
      // Caso WebView (mobile) usando JavaScriptChannel
      if (window.MapboxChannel && typeof window.MapboxChannel.postMessage === 'function') {
        window.MapboxChannel.postMessage(JSON.stringify(payload));
      }
    }

    function addMarkers(list) {
      list.forEach(m => {
        const marker = new mapboxgl.Marker({ color: m.color })
          .setLngLat([m.lon, m.lat]);

        if (m.label && m.label.length > 0) {
          marker.setPopup(new mapboxgl.Popup().setText(m.label));
        }

        const el = marker.getElement();
        el.addEventListener('click', () => {
          const payload = {
            type: 'markerClick',
            viewId: SIGED_VIEW_ID,
            idExtra: m.idExtra || '',
            label: m.label || '',
            lon: m.lon,
            lat: m.lat,
          };
          notifyMarkerClick(payload);
        });

        marker.addTo(map);
        flutterMarkers.push(marker);
      });
    }

    function updateMarkersFromFlutter(markers) {
      currentMarkersData = markers.slice();
      clearMarkers();
      addMarkers(markers);
    }

    function applyTerrainAndFog() {
      if (cfg.enableTerrain) {
        if (!map.getSource('mapbox-dem')) {
          map.addSource('mapbox-dem', {
            type: 'raster-dem',
            url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
            tileSize: 512,
            maxzoom: 14
          });
        }
        map.setTerrain({ source: 'mapbox-dem', exaggeration: cfg.terrainExaggeration ?? 1.5 });
      }

      if (cfg.enableFog) {
        map.setFog({});
      } else {
        map.setFog(null);
      }

      if (cfg.enable3DBuildings) {
        const layer = map.getStyle().layer;
        let labelLayerId;
        for (const layer of layer) {
          if (layer.type === 'symbol' && layer.layout && layer.layout['text-table']) {
            labelLayerId = layer.id;
            break;
          }
        }

        if (!map.getLayer('3d-buildings')) {
          map.addLayer(
            {
              id: '3d-buildings',
              source: 'composite',
              'source-layer': 'building',
              filter: ['==', 'extrude', 'true'],
              type: 'fill-extrusion',
              minzoom: 15,
              paint: {
                'fill-extrusion-color': '#aaa',
                'fill-extrusion-height': [
                  'interpolate',
                  ['linear'],
                  ['zoom'],
                  15, 0,
                  15.05, ['get', 'height']
                ],
                'fill-extrusion-base': [
                  'interpolate',
                  ['linear'],
                  ['zoom'],
                  15, 0,
                  15.05, ['get', 'min_height']
                ],
                'fill-extrusion-opacity': 0.6
              }
            },
            labelLayerId
          );
        }
      }
    }

    function createMap(styleUrl) {
      if (!styleUrl) {
        styleUrl = cfg.styleUrl || 'mapbox://styles/mapbox/streets-v12';
      }

      map = new mapboxgl.Map({
        container: 'map',
        style: styleUrl,
        center: [cfg.centerLon, cfg.centerLat],
        zoom: cfg.zoom,
        pitch: cfg.pitch,
        bearing: cfg.bearing,
        antialias: true,
        minZoom: cfg.minZoom ?? 0,
        maxZoom: cfg.maxZoom ?? 22,
        attributionControl: false
      });

      map.addControl(
        new mapboxgl.AttributionControl({
          compact: true,
          customAttribution: cfg.customAttribution || '© SipGed'
        }),
        'bottom-right'
      );

      if (cfg.showNavigationControl) {
        map.addControl(new mapboxgl.NavigationControl(), 'bottom-right');
      }
      if (cfg.showScaleControl) {
        map.addControl(new mapboxgl.ScaleControl(), 'bottom-left');
      }
      if (cfg.showFullscreenControl) {
        map.addControl(new mapboxgl.FullscreenControl(), 'top-left');
      }

      if (!cfg.enableScrollZoom) map.scrollZoom.disable();
      if (!cfg.enableRotateGestures) map.dragRotate.disable();
      if (!cfg.enableDoubleClickZoom) map.doubleClickZoom.disable();
      if (!cfg.enableDragPan) map.dragPan.disable();

      map.on('load', () => {
        applyTerrainAndFog();

        try {
          const initial = $initialMarkersJson;
          updateMarkersFromFlutter(initial);
        } catch (e) {
          console.error('Erro ao carregar marcadores iniciais', e);
        }
      });

      map.on('style.load', () => {
        applyTerrainAndFog();
        if (currentMarkersData && currentMarkersData.length > 0) {
          updateMarkersFromFlutter(currentMarkersData);
        }
      });
    }

    // ------------------------------------------------------------------
    // Funções chamadas pelo Flutter (WebView ou iframe)
    // ------------------------------------------------------------------
    function handleCameraMessage(data) {
      if (!map) return;
      const method = data.method;
      const params = data.params || {};

      if (method === 'setCamera') {
        const bearing = typeof params.bearing === 'number'
          ? params.bearing
          : map.getBearing();
        const pitch = typeof params.pitch === 'number'
          ? params.pitch
          : map.getPitch();
        const zoom = typeof params.zoom === 'number'
          ? params.zoom
          : map.getZoom();
        const duration = params.durationMs ?? 0;

        map.easeTo({ bearing, pitch, zoom, duration });
      }

      if (method === 'deltaCamera') {
        const dBearing = params.dBearing ?? 0;
        const dPitch = params.dPitch ?? 0;
        const dZoom = params.dZoom ?? 0;
        const duration = params.durationMs ?? 0;

        map.easeTo({
          bearing: map.getBearing() + dBearing,
          pitch: Math.max(0, Math.min(80, map.getPitch() + dPitch)),
          zoom: map.getZoom() + dZoom,
          duration
        });
      }

      if (method === 'setStyle') {
        const styleUrl = params.styleUrl || cfg.styleUrl;
        map.setStyle(styleUrl);
      }
    }

    function handleUpdateMarkers(data) {
      if (Array.isArray(data.markers)) {
        updateMarkersFromFlutter(data.markers);
      }
    }

    // Chamadas diretas do Flutter (mobile) via runJavaScript
    window.flutterMapboxCameraControl = function(data) {
      if (!data || typeof data !== 'object') return;
      if (data.type === 'cameraControl') {
        handleCameraMessage(data);
      } else if (data.type === 'updateMarkers') {
        handleUpdateMarkers(data);
      }
    };

    window.flutterMapboxUpdateMarkers = function(data) {
      if (!data || typeof data !== 'object') return;
      handleUpdateMarkers(data);
    };

    // Mensagens vindas do Flutter na Web (iframe → postMessage)
    window.addEventListener('message', (event) => {
      const data = event.data;
      if (!data || typeof data !== 'object') return;

      if (data.type === 'updateMarkers') {
        handleUpdateMarkers(data);
      }

      if (data.type === 'cameraControl') {
        handleCameraMessage(data);
      }
    });

    // Inicializa o mapa
    createMap(cfg.styleUrl);
  </script>
</body>
</html>
''';
}
