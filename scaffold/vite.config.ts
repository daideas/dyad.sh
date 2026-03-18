import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path'; // <--- ESTA LÍNEA ES VITAL

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Esto le dice a Vite que @ significa la carpeta src
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: 'dist', // Asegura que el output vaya a dist
    emptyOutDir: true,
  }
});
