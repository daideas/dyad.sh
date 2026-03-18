import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path' // <--- Esto es lo que resuelve el error

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Aquí le decimos a Vite que @ es la carpeta /src
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  }
})
