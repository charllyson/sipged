// tools/ifc_bundle/rollup.config.mjs
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "index.js",
  output: {
    file: "dist/ifc_bundle.js",
    format: "iife",        // bundle tradicional, sem import/export
    name: "SigedIfcBundle" // nome do IIFE; não afeta window.SigedIfc
  },
  plugins: [resolve()],
};
