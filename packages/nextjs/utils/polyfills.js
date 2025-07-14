// Polyfill para indexedDB no ambiente Node.js (SSR)
if (typeof global !== "undefined" && !global.indexedDB) {
  // Mock simples do indexedDB para evitar erros durante SSR
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

// Polyfill para outras APIs do browser que podem causar problemas
if (typeof global !== "undefined") {
  if (!global.localStorage) {
    global.localStorage = {
      getItem: () => null,
      setItem: () => {},
      removeItem: () => {},
      clear: () => {},
      length: 0,
      key: () => null,
    };
  }

  if (!global.sessionStorage) {
    global.sessionStorage = {
      getItem: () => null,
      setItem: () => {},
      removeItem: () => {},
      clear: () => {},
      length: 0,
      key: () => null,
    };
  }
}
