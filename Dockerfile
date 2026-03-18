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

# --- SOLUCIÓN AL ERROR DE NODE-LINKER ---
# Creamos el archivo .npmrc físicamente para que Electron Forge lo detecte
RUN echo "node-linker=hoisted" > .npmrc

# Variables para limpiar logs
ENV PNPM_NODE_LINKER=hoisted
ENV NPM_CONFIG_LOGLEVEL=error

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Ejecutamos el build original
RUN pnpm run build || true

# Enlace para Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor estático
RUN npm install -g serve

EXPOSE 3000

# Comando de arranque inteligente
CMD ["sh", "-c", "if [ -d \".vite/renderer/main_window\" ]; then serve -s .vite/renderer/main_window -l 3000; else serve -s dist -l 3000; fi"]
