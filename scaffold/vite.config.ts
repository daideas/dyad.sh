import { defineConfig } from 'vite';
import path from 'path'; // 1. Asegúrate de que esta línea esté arriba

export default defineConfig({
  // ... aquí pueden haber otras cosas como plugins: []
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'), // 2. Esta es la línea mágica
    },
  },
  // ... resto de tu configuración
});
