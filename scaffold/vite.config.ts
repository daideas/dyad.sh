import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path' // <-- Esto es lo que resuelve el error

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Aquí le decimos a Vite que @ significa la carpeta /src
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: 'dist', // Asegura que los archivos vayan a la carpeta dist
    emptyOutDir: true,
  }
})
