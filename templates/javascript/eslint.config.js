import js from "@eslint/js";
import globals from "globals";

export default [
  {
    ignores: ["node_modules/**", "coverage/**", "dist/**"]
  },
  js.configs.recommended,
  {
    files: ["**/*.js", "**/*.mjs"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      // Both runtimes are valid in this harness (src/node and src/browser).
      globals: {
        ...globals.node,
        ...globals.browser
      }
    }
  }
];
