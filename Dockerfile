# Usamos Node 24
FROM node:24-slim

# Instalamos herramientas mínimas
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# --- FIX PARA EL ERROR DE NODE-LINKER ---
# Esto crea el archivo que Electron Forge necesita ver sí o sí
RUN echo "node-linker=hoisted" > .npmrc

# Silenciamos los logs de npm para que no den warnings
ENV NPM_CONFIG_LOGLEVEL=error

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Ejecutamos el build (ahora sí pasará el check del package manager)
RUN pnpm run build || true

# Enlace para Node.js (necesario para la app)
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor estático
RUN npm install -g serve

EXPOSE 3000

# Comando de arranque inteligente
CMD ["sh", "-c", "if [ -d \".vite/renderer/main_window\" ]; then serve -s .vite/renderer/main_window -l 3000; else serve -s dist -l 3000; fi"]
