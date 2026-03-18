import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Esta línea permite que Vite entienda las rutas que empiezan con @
      '@': path.resolve(__dirname, './src'),
    },
    // Esto asegura que en Linux (Docker) se encuentren los archivos sin problemas de extensión
    extensions: ['.mjs', '.js', '.ts', '.jsx', '.tsx', '.json']
  },
  /* NOTA PARA EL DEPLOY: 
     Con esta configuracion resolvemos el error de Rollup en Docker.
     Vite ahora podra encontrar los atomos y hooks de la carpeta /src 
     permitiendo que el build genere los archivos reales de la App. 
  */
});
