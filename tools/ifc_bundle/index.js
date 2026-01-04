// tools/ifc_bundle/index.js
import { IfcViewerAPI } from "web-ifc-viewer";

window.SigedIfc = {
    createViewer(options) {
        const viewer = new IfcViewerAPI({
            container: options.container,
        });

        if (viewer.IFC && typeof viewer.IFC.setWasmPath === "function") {
            viewer.IFC.setWasmPath("/wasm/");
            console.log("[IFC_VIEWER] setWasmPath('/wasm/')");
        }

        if (viewer.axes && viewer.axes.setAxes) viewer.axes.setAxes();
        if (viewer.grid && viewer.grid.setGrid) viewer.grid.setGrid();

        return viewer;
    },
};
