import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path' // <-- Esto es obligatorio

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Esto traduce la @ para el servidor Linux
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
