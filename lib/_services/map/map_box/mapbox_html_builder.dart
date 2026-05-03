// lib/_services/map/map_box/mapbox_html_builder.dart
import 'dart:convert';

import 'package:sipged/_services/map/map_box/mapbox_data.dart';

String buildMapboxHtml(
    MapboxMapConfig config, {
      required String viewId,
    }) {
  final cfgJson = jsonEncode(config.toJsonForHtml());

  final initialMarkersJson = jsonEncode(
    config.markers.map((m) => m.toJson()).toList(growable: false),
  );

  return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
  <title>Mapbox 3D - SIPGED</title>

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
      background: transparent;
    }

    #map {
      position: absolute;
      top: 0;
      left: 0;
    }

    .mapboxgl-popup-content {
      font-size: 13px;
      line-height: 1.25;
      border-radius: 6px;
      padding: 8px 10px;
    }
  </style>
</head>

<body>
  <div id="map"></div>

  <script>
    const cfg = $cfgJson;
    const SIGED_VIEW_ID = '$viewId';

    mapboxgl.accessToken = cfg.accessToken;

    let map = null;
    let flutterMarkers = [];
    let currentMarkersData = [];
    let pendingMarkersData = $initialMarkersJson;

    function safeNumber(value, fallback) {
      return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
    }

    function clearMarkers() {
      for (const marker of flutterMarkers) {
        try {
          marker.remove();
        } catch (e) {}
      }

      flutterMarkers = [];
    }

    function notifyMarkerClick(payload) {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(payload, '*');
      }

      if (
        window.MapboxChannel &&
        typeof window.MapboxChannel.postMessage === 'function'
      ) {
        window.MapboxChannel.postMessage(JSON.stringify(payload));
      }
    }

    function addMarkers(list) {
      if (!map || !Array.isArray(list)) return;

      for (const m of list) {
        const lon = safeNumber(m.lon, null);
        const lat = safeNumber(m.lat, null);

        if (lon === null || lat === null) continue;
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

        const markerColor = m.color || m.colorHex || '#ff3333';

        const marker = new mapboxgl.Marker({
          color: markerColor
        }).setLngLat([lon, lat]);

        if (m.label && String(m.label).length > 0) {
          marker.setPopup(
            new mapboxgl.Popup({
              closeButton: true,
              closeOnClick: false,
              offset: 25
            }).setText(String(m.label))
          );
        }

        const el = marker.getElement();

        el.style.cursor = 'pointer';

        el.addEventListener('click', (event) => {
          event.stopPropagation();

          const payload = {
            type: 'markerClick',
            viewId: SIGED_VIEW_ID,
            idExtra: m.idExtra || '',
            label: m.label || '',
            lon: lon,
            lat: lat
          };

          notifyMarkerClick(payload);
        });

        marker.addTo(map);

        // CORREÇÃO PRINCIPAL:
        // antes estava flutterMarkers.remote(marker);
        flutterMarkers.push(marker);
      }
    }

    function updateMarkersFromFlutter(markers) {
      if (!Array.isArray(markers)) return;

      currentMarkersData = markers.slice();

      if (!map || !map.loaded()) {
        pendingMarkersData = currentMarkersData;
        return;
      }

      clearMarkers();
      addMarkers(currentMarkersData);
    }

    function applyTerrainAndFog() {
      if (!map) return;

      try {
        if (cfg.enableTerrain) {
          if (!map.getSource('mapbox-dem')) {
            map.addSource('mapbox-dem', {
              type: 'raster-dem',
              url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
              tileSize: 512,
              maxzoom: 14
            });
          }

          map.setTerrain({
            source: 'mapbox-dem',
            exaggeration: cfg.terrainExaggeration ?? 1.5
          });
        } else {
          map.setTerrain(null);
        }
      } catch (e) {
        console.warn('Falha ao aplicar terreno:', e);
      }

      try {
        if (cfg.enableFog) {
          map.setFog({});
        } else {
          map.setFog(null);
        }
      } catch (e) {
        console.warn('Falha ao aplicar fog:', e);
      }

      try {
        if (!cfg.enable3DBuildings) return;

        const style = map.getStyle();
        const layers = style && Array.isArray(style.layers) ? style.layers : [];

        let labelLayerId = null;

        for (const layer of layers) {
          if (
            layer.type === 'symbol' &&
            layer.layout &&
            layer.layout['text-field']
          ) {
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
                  15,
                  0,
                  15.05,
                  ['get', 'height']
                ],
                'fill-extrusion-base': [
                  'interpolate',
                  ['linear'],
                  ['zoom'],
                  15,
                  0,
                  15.05,
                  ['get', 'min_height']
                ],
                'fill-extrusion-opacity': 0.6
              }
            },
            labelLayerId
          );
        }
      } catch (e) {
        console.warn('Falha ao aplicar prédios 3D:', e);
      }
    }

    function createMap(styleUrl) {
      const resolvedStyleUrl =
        styleUrl || cfg.styleUrl || 'mapbox://styles/mapbox/streets-v12';

      map = new mapboxgl.Map({
        container: 'map',
        style: resolvedStyleUrl,
        center: [
          safeNumber(cfg.centerLon, -36.5),
          safeNumber(cfg.centerLat, -9.6)
        ],
        zoom: safeNumber(cfg.zoom, 5),
        pitch: safeNumber(cfg.pitch, 0),
        bearing: safeNumber(cfg.bearing, 0),
        antialias: true,
        minZoom: cfg.minZoom ?? 0,
        maxZoom: cfg.maxZoom ?? 22,
        attributionControl: false
      });

      map.addControl(
        new mapboxgl.AttributionControl({
          compact: true,
          customAttribution: cfg.customAttribution || '© SIPGED'
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

        const initial = Array.isArray(pendingMarkersData)
          ? pendingMarkersData
          : [];

        currentMarkersData = initial.slice();

        clearMarkers();
        addMarkers(currentMarkersData);
      });

      map.on('style.load', () => {
        applyTerrainAndFog();

        if (currentMarkersData && currentMarkersData.length > 0) {
          clearMarkers();
          addMarkers(currentMarkersData);
        }
      });

      map.on('error', (e) => {
        console.warn('Mapbox error:', e && e.error ? e.error : e);
      });
    }

    function handleCameraMessage(data) {
      if (!map || !data) return;

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

        map.easeTo({
          bearing: bearing,
          pitch: Math.max(0, Math.min(80, pitch)),
          zoom: zoom,
          duration: duration
        });
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
          duration: duration
        });
      }

      if (method === 'setStyle') {
        const styleUrl = params.styleUrl || cfg.styleUrl;
        map.setStyle(styleUrl);
      }
    }

    function handleUpdateMarkers(data) {
      if (!data) return;

      if (Array.isArray(data.markers)) {
        updateMarkersFromFlutter(data.markers);
      }
    }

    window.flutterMapboxCameraControl = function(data) {
      if (!data || typeof data !== 'object') return;

      if (data.type === 'cameraControl') {
        handleCameraMessage(data);
      }

      if (data.type === 'updateMarkers') {
        handleUpdateMarkers(data);
      }
    };

    window.flutterMapboxUpdateMarkers = function(data) {
      if (!data || typeof data !== 'object') return;
      handleUpdateMarkers(data);
    };

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

    createMap(cfg.styleUrl);
  </script>
</body>
</html>
''';
}