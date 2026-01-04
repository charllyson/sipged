// lib/_services/map/cesium/cesium_html_builder.dart
import 'dart:convert';

import 'package:siged/_blocs/map/cesium/cesium_map_config.dart';

/// Gera o HTML completo para o CesiumJS.
String buildCesiumHtml(
    CesiumMapConfig config, {
      required String viewId,
    }) {
  final cfgJson = jsonEncode(config.toJsonForHtml());
  final markersJson = jsonEncode(
    config.markers.map((m) => m.toJson()).toList(),
  );

  return """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>CesiumJS - SIGED</title>

  <script src="https://cesium.com/downloads/cesiumjs/releases/1.118/Build/Cesium/Cesium.js"></script>
  <link href="https://cesium.com/downloads/cesiumjs/releases/1.118/Build/Cesium/Widgets/widgets.css" rel="stylesheet"/>

  <style>
    html, body, #cesiumContainer {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #000;
    }
  </style>
</head>

<body>
  <div id="cesiumContainer"></div>

  <script>
    const CFG = $cfgJson;
    const MARKERS = $markersJson;
    const VIEW_ID = "$viewId";

    (async function initCesium() {
      try {
        Cesium.Ion.defaultAccessToken = CFG.accessToken || "";

        const viewer = new Cesium.Viewer("cesiumContainer", {
          animation: false,
          timeline: false,
          fullscreenButton: false,
          geocoder: false,
          sceneModePicker: false,
          baseLayerPicker: false,
          navigationHelpButton: false,
          homeButton: true,
          infoBox: true,
          selectionIndicator: true,
        });

        viewer.scene.globe.show = true;
        viewer.scene.globe.enableLighting = true;
        viewer.scene.globe.showGroundAtmosphere = true;
        viewer.scene.skyAtmosphere.show = true;
        viewer.scene.skyBox.show = true;
        viewer.scene.highDynamicRange = true;
        viewer.scene.globe.depthTestAgainstTerrain = false;
        viewer.scene.backgroundColor = new Cesium.Color(0.0, 0.0, 0.0, 1.0);

        const pinBuilder = new Cesium.PinBuilder();

        function colorFromHex(hex, fallback) {
          if (!hex || typeof hex !== "string" || !hex.trim()) {
            return fallback;
          }
          try {
            return Cesium.Color.fromCssColorString(hex);
          } catch (e) {
            console.warn("Cor inválida em marker:", hex, e);
            return fallback;
          }
        }

        function addMarkers(markers) {
          const defaultColor = Cesium.Color.fromCssColorString("#ff6600");

          markers.forEach((m) => {
            const position = Cesium.Cartesian3.fromDegrees(m.lon, m.lat);
            const pinColor = colorFromHex(m.colorHex, defaultColor);

            pinBuilder.fromColor(pinColor, 48).then(function(canvas) {
              const entity = viewer.entities.add({
                position: position,
                billboard: {
                  image: canvas.toDataURL(),
                  verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
                  scale: 1.0,
                  disableDepthTestDistance: Number.POSITIVE_INFINITY,
                },
                label: m.label && m.label.length > 0
                  ? {
                      text: m.label,
                      font: "13px sans-serif",
                      fillColor: Cesium.Color.WHITE,
                      outlineColor: Cesium.Color.BLACK,
                      outlineWidth: 2,
                      style: Cesium.LabelStyle.FILL_AND_OUTLINE,
                      pixelOffset: new Cesium.Cartesian2(0, -50),
                      disableDepthTestDistance: Number.POSITIVE_INFINITY,
                    }
                  : undefined,
              });

              entity._sigedData = {
                idExtra: m.idExtra || "",
                label: m.label || "",
                lon: m.lon,
                lat: m.lat,
              };
            }).catch(function(e) {
              console.error("Erro ao gerar pin:", e);
            });
          });
        }

        // Marcadores iniciais
        try {
          if (Array.isArray(MARKERS) && MARKERS.length > 0) {
            addMarkers(MARKERS);
          }
        } catch (e) {
          console.error("Erro ao adicionar marcadores iniciais:", e);
        }

        // --- Câmera inicial (sem animação) ----------------------------------
        const initialHeight = CFG.height && CFG.height > 0 ? CFG.height : 3000000.0;

        // 🔁 Troquei o flyTo (com duração) por setView (sem animação)
        viewer.camera.setView({
          destination: Cesium.Cartesian3.fromDegrees(
            CFG.lon,
            CFG.lat,
            initialHeight
          )
        });

        // Clique em marcador → postMessage para Flutter
        const handler = new Cesium.ScreenSpaceEventHandler(viewer.scene.canvas);
        handler.setInputAction(function(click) {
          const picked = viewer.scene.pick(click.position);

          if (Cesium.defined(picked) && picked.id && picked.id._sigedData) {
            const info = picked.id._sigedData;

            if (window.parent && window.parent !== window) {
              window.parent.postMessage({
                type: "markerClick",
                viewId: VIEW_ID,
                idExtra: info.idExtra,
                label: info.label,
                lon: info.lon,
                lat: info.lat,
              }, "*");
            }
          }
        }, Cesium.ScreenSpaceEventType.LEFT_CLICK);

        // Mensagens vindas do Flutter
        window.addEventListener("message", function(event) {
          const data = event.data;
          if (!data || typeof data !== "object") return;

          // Continua podendo usar flyTo via controller (com animação)
          if (data.type === "camera" &&
              data.method === "flyTo" &&
              data.viewId === VIEW_ID) {

            const lon = (typeof data.lon === "number") ? data.lon : CFG.lon;
            const lat = (typeof data.lat === "number") ? data.lat : CFG.lat;
            const height = (typeof data.height === "number")
              ? data.height
              : initialHeight;
            const duration = (typeof data.duration === "number") ? data.duration : 1.5;

            viewer.camera.flyTo({
              destination: Cesium.Cartesian3.fromDegrees(lon, lat, height),
              duration: duration
            });
          }

          if (data.type === "updateMarkers" &&
              data.viewId === VIEW_ID &&
              Array.isArray(data.markers)) {

            viewer.entities.removeAll();
            try {
              addMarkers(data.markers);
            } catch (e) {
              console.error("Erro ao atualizar marcadores:", e);
            }
          }
        });
      } catch (err) {
        console.error("Erro ao inicializar Cesium:", err);
      }
    })();
  </script>
</body>
</html>
""";
}
