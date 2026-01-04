// web/mapbox_3d.js

function initMapbox3D(containerId, accessToken) {
    mapboxgl.accessToken = accessToken;

    const map = new mapboxgl.Map({
        container: containerId,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [-43.2096, -22.9035], // Altere para sua região
        zoom: 15.5,
        pitch: 60,
        bearing: 30,
        antialias: true,
    });

    map.on('load', () => {
        const layers = map.getStyle().layers;
        let labelLayerId = null;

        for (let i = 0; i < layers.length; i++) {
            const layer = layers[i];
            if (
            layer.type === 'symbol' &&
            layer.layout &&
            layer.layout['text-field']
            ) {
                labelLayerId = layer.id;
                break;
            }
        }

        // Add prédios 3D
        map.addLayer(
            {
                id: '3d-buildings',
                source: 'composite',
                'source-layer': 'building',
                filter: ['==', ['get', 'extrude'], 'true'],
                type: 'fill-extrusion',
                minzoom: 15,
                paint: {
                    'fill-extrusion-color': '#aaaaaa',
                    'fill-extrusion-height': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        15,
                        0,
                        15.05,
                        ['get', 'height'],
                    ],
                    'fill-extrusion-base': ['get', 'min_height'],
                    'fill-extrusion-opacity': 0.9,
                },
            },
            labelLayerId
        );
    });

    return map;
}
