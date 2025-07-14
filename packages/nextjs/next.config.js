// @ts-check

// Carregar polyfills imediatamente
require("./utils/polyfills.js");

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  typescript: {
    ignoreBuildErrors: process.env.NEXT_PUBLIC_IGNORE_BUILD_ERROR === "true",
  },
  eslint: {
    ignoreDuringBuilds: process.env.NEXT_PUBLIC_IGNORE_BUILD_ERROR === "true",
  },
  webpack: config => {
    // Polyfill para indexedDB no ambiente Node.js (SSR)
    config.resolve.alias = {
      ...config.resolve.alias,
    };

    config.resolve.fallback = { fs: false, net: false, tls: false };
    config.externals.push("pino-pretty", "lokijs", "encoding");

    // Adicionar fallbacks para APIs do browser que não existem no Node.js
    config.resolve.fallback = {
      ...config.resolve.fallback,
      crypto: false,
      stream: false,
      assert: false,
      http: false,
      https: false,
      os: false,
      url: false,
    };

    // Injetar polyfills globalmente
    const originalEntry = config.entry;
    config.entry = async () => {
      const entries = await originalEntry();

      // Polyfill para indexedDB
      if (typeof global !== "undefined" && !global.indexedDB) {
        global.indexedDB = {
          open: () => ({
            addEventListener: () => {},
            removeEventListener: () => {},
            result: {
              createObjectStore: () => ({}),
              transaction: () => ({
                objectStore: () => ({
                  add: () => ({ addEventListener: () => {} }),
                  put: () => ({ addEventListener: () => {} }),
                  get: () => ({ addEventListener: () => {} }),
                  delete: () => ({ addEventListener: () => {} }),
                  clear: () => ({ addEventListener: () => {} }),
                }),
              }),
            },
          }),
          deleteDatabase: () => ({ addEventListener: () => {} }),
        };
      }

      return entries;
    };

    return config;
  },
};

module.exports = nextConfig;
