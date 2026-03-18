# Usamos Node 24
FROM node:24-slim

# Instalamos herramientas mínimas de compilación
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Forzamos el modo hoisted para evitar líos de rutas
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# --- EL CAMBIO CLAVE ---
# En lugar de 'pnpm run build' (que llama a Electron), 
# llamamos directamente a la compilación de la web (Vite)
RUN npx vite build

EXPOSE 3000

# Para arrancar, usamos el servidor de previsualización de Vite 
# que servirá la carpeta 'dist' por el puerto 3000
CMD ["npx", "vite", "preview", "--port", "3000", "--host"]
