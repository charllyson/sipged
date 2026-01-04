// lib/_services/ifc/ifc_viewer_html_builder.dart
import 'dart:convert';

import 'package:siged/_blocs/ifc/ifc_viewer_data.dart';

/// Gera o HTML que será injetado no iframe (Web) ou carregado no WebView (mobile)
/// para visualizar o modelo IFC usando o bundle ifc_bundle.js (web-ifc-viewer).
///
/// - ifc_bundle.js fica em web/ifc_bundle.js
/// - wasm do web-ifc fica em web/wasm/
///
/// Aceita opcionalmente um IFC já em base64 para carregar automaticamente.
String buildIfcViewerHtml(
    IfcViewerConfig config, {
      String? initialIfcBase64,
      String? initialFileName,
    }) {
  final cfgJson = jsonEncode(config.toJson());
  final bgColor = config.backgroundColorHex;

  // Strings JS seguras
  final initialB64Js = jsonEncode(initialIfcBase64 ?? '');
  final initialNameJs = jsonEncode(initialFileName ?? 'modelo.ifc');

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>IFC Viewer</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <style>
    html, body {
      margin: 0;
      padding: 0;
      overflow: hidden;
      width: 100%;
      height: 100%;
      background: $bgColor;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    #viewer-container {
      width: 100%;
      height: 100%;
      background: #111;
      position: relative;
    }
    #viewer-overlay {
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      padding: 6px 12px;
      color: #ddd;
      font-size: 13px;
      background: rgba(20,20,20,0.85);
      display: flex;
      justify-content: space-between;
      align-items: center;
      pointer-events: none;
      z-index: 10;
    }
    #viewer-log {
      position: absolute;
      left: 8px;
      bottom: 8px;
      right: 8px;
      max-height: 30%;
      overflow: auto;
      font-family: monospace;
      font-size: 11px;
      color: #ccc;
      background: rgba(0,0,0,0.6);
      padding: 6px 8px;
      border-radius: 6px;
      box-sizing: border-box;
      pointer-events: none;
      white-space: pre-wrap;
    }
  </style>
</head>
<body>
  <div id="viewer-container">
    <div id="viewer-overlay">
      <span>IFC.js Viewer</span>
      <span id="viewer-status">Carregando bundle IFC…</span>
    </div>
    <div id="viewer-log"></div>
  </div>

  <script>
    const CFG = $cfgJson;
    const SIGED_VIEW_ID = CFG.viewId || 'IFC_VIEW';

    // IFC inicial embutido (opcional)
    const INITIAL_IFC_BASE64 = $initialB64Js;
    const INITIAL_IFC_FILENAME = $initialNameJs;

    const viewerContainer = document.getElementById('viewer-container');
    const viewerStatus = document.getElementById('viewer-status');
    const viewerLog = document.getElementById('viewer-log');

    let viewer = null;
    let viewerReady = false;
    let pendingIfcLoad = null;

    function appendLog(msg) {
      const time = new Date().toISOString().substr(11, 8);
      if (!viewerLog) return;
      viewerLog.textContent += '[' + time + '] ' + msg + '\\n';
      viewerLog.scrollTop = viewerLog.scrollHeight;
      console.log('[IFC_VIEWER]', msg);
    }

    async function loadIfcFromBase64(base64Str, fileName) {
      try {
        appendLog('loadIfcFromBase64 chamado. viewerReady=' + viewerReady);

        if (!base64Str) {
          appendLog('Base64 vazio recebido, nada para carregar.');
          return;
        }

        if (!viewerReady || !viewer) {
          appendLog('Viewer ainda não pronto. Armazenando IFC pendente…');
          pendingIfcLoad = { base64: base64Str, fileName: fileName };
          return;
        }

        const binary = atob(base64Str);
        const len = binary.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
          bytes[i] = binary.charCodeAt(i);
        }

        const blob = new Blob([bytes], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);

        appendLog('IFC recebido (embutido ou mensagem): ' + (fileName || 'sem_nome.ifc'));
        appendLog('URL em memória criada: ' + url);

        if (viewerStatus) {
          viewerStatus.textContent =
            'Carregando modelo "' + (fileName || 'IFC') + '"…';
        }

        const model = await viewer.IFC.loadIfcUrl(url);

        // ---------- DEBUG SOBRE O RETORNO ----------
        let modelId = null;
        if (typeof model === 'number') {
          modelId = model;
          appendLog('Retorno loadIfcUrl é um número (modelId=' + modelId + ').');
        } else if (model && typeof model.modelID === 'number') {
          modelId = model.modelID;
          appendLog('Retorno loadIfcUrl é objeto com modelID=' + modelId + '.');
        } else {
          appendLog('Retorno loadIfcUrl tipo=' + (typeof model) + '.');
          try {
            const keys = Object.keys(model || {});
            appendLog('Chaves do retorno loadIfcUrl: ' + keys.join(', '));
          } catch (e) {}
        }

        try {
          const items = viewer.context && viewer.context.items;
          const ifcModels = items && items.ifcModels ? items.ifcModels : [];
          const meshes = items && items.meshes ? Array.from(items.meshes) : [];
          appendLog('Qtd ifcModels no viewer: ' + (ifcModels.length || 0));
          appendLog('Qtd meshes em context.items.meshes: ' + (meshes.length || 0));
        } catch (e) {
          appendLog('Erro ao inspecionar viewer.context.items: ' + e);
        }
        // -------------------------------------------

        // ---------- AJUSTE DE CÂMERA ----------
        try {
          let fitDone = false;

          if (viewer.IFC && typeof viewer.IFC.fitToFrame === 'function') {
            appendLog('Chamando viewer.IFC.fitToFrame()…');
            if (modelId !== null && modelId !== undefined) {
              await viewer.IFC.fitToFrame(modelId);
              appendLog('viewer.IFC.fitToFrame(modelId) concluído.');
            } else {
              await viewer.IFC.fitToFrame();
              appendLog('viewer.IFC.fitToFrame() (sem id) concluído.');
            }
            fitDone = true;
          }

          if (!fitDone &&
              viewer.context &&
              viewer.context.ifcCamera &&
              typeof viewer.context.ifcCamera.fitModelToFrame === 'function') {

            appendLog('Chamando viewer.context.ifcCamera.fitModelToFrame()…');
            if (modelId !== null && modelId !== undefined) {
              viewer.context.ifcCamera.fitModelToFrame(modelId);
              appendLog('fitModelToFrame(modelId) chamado.');
            } else {
              viewer.context.ifcCamera.fitModelToFrame();
              appendLog('fitModelToFrame() sem id chamado.');
            }
            fitDone = true;
          }

          if (!fitDone) {
            appendLog('Nenhum método de fitToFrame encontrado (IFC.fitToFrame ou ifcCamera.fitModelToFrame).');
          }
        } catch (camErr) {
          appendLog('Erro ao ajustar câmera: ' + camErr);
        }
        // --------------------------------------

        if (viewerStatus) {
          viewerStatus.textContent =
            'Modelo "' + (fileName || 'IFC') + '" carregado.';
        }

        appendLog('Modelo IFC carregado com sucesso.');
      } catch (err) {
        console.error('Erro ao carregar IFC base64:', err);
        appendLog('Erro ao carregar IFC base64: ' + err);
        if (viewerStatus) {
          viewerStatus.textContent = 'Erro ao carregar modelo IFC.';
        }
      }
    }

    function initViewer() {
      try {
        if (!window.SigedIfc || !window.SigedIfc.createViewer) {
          appendLog('window.SigedIfc.createViewer não encontrado. Verifique se ifc_bundle.js foi carregado.');
          if (viewerStatus) {
            viewerStatus.textContent =
              'Erro: ifc_bundle.js não expôs SigedIfc.createViewer.';
          }
          return;
        }

        const options = {
          container: viewerContainer,
        };

        viewer = window.SigedIfc.createViewer(options);
        viewerReady = true;

        try {
          if (viewer.context &&
              viewer.context.renderer &&
              viewer.context.renderer.postProduction) {
            viewer.context.renderer.postProduction.active = true;
            appendLog('postProduction ativo = true');
          }
        } catch (ppErr) {
          appendLog('Aviso ao ajustar postProduction: ' + ppErr);
        }

        appendLog('Viewer IFC inicializado com sucesso. viewId=' + SIGED_VIEW_ID);
        if (viewerStatus) {
          viewerStatus.textContent = 'Viewer pronto. Aguardando modelo IFC…';
        }

        // Se veio um IFC embutido, já carrega
        if (INITIAL_IFC_BASE64 && INITIAL_IFC_BASE64.length > 0) {
          appendLog('Encontrado IFC embutido no HTML. Carregando automaticamente…');
          loadIfcFromBase64(INITIAL_IFC_BASE64, INITIAL_IFC_FILENAME || 'modelo.ifc');
        } else if (pendingIfcLoad) {
          appendLog('Carregando IFC pendente após initViewer…');
          loadIfcFromBase64(pendingIfcLoad.base64, pendingIfcLoad.fileName);
          pendingIfcLoad = null;
        }
      } catch (err) {
        console.error(err);
        appendLog('Erro ao inicializar viewer: ' + err);
        if (viewerStatus) {
          viewerStatus.textContent = 'Erro ao inicializar viewer.';
        }
      }
    }

    // Ainda deixo exposto globalmente se um dia quiser mandar via mensagem
    window.loadIfcFromBase64 = loadIfcFromBase64;

    appendLog('HTML do IFC Viewer carregado. Carregando ifc_bundle.js…');

    (function loadBundle() {
      const script = document.createElement('script');

      let baseOrigin = '';
      try {
        if (window.parent && window.parent.location && window.parent.location.origin) {
          baseOrigin = window.parent.location.origin;
        } else if (window.location && window.location.origin) {
          baseOrigin = window.location.origin;
        }
      } catch (err) {}

      script.src = baseOrigin + '/ifc_bundle.js';

      appendLog('Tentando carregar ifc_bundle.js de: ' + script.src);

      script.onload = () => {
        appendLog('ifc_bundle.js carregado. Inicializando viewer IFC.js…');
        if (viewerStatus) {
          viewerStatus.textContent = 'Inicializando viewer IFC.js…';
        }
        initViewer();
      };
      script.onerror = (e) => {
        appendLog('Erro ao carregar ifc_bundle.js: ' + (e && e.message));
        if (viewerStatus) {
          viewerStatus.textContent = 'Erro ao carregar ifc_bundle.js.';
        }
      };
      document.head.appendChild(script);
    })();
  </script>
</body>
</html>
''';
}
