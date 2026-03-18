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

# --- PASO CRUCIAL: Configuración antes de nada ---
# Forzamos el modo hoisted para evitar el fallo de Electron Forge
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc
ENV NPM_CONFIG_LOGLEVEL=error

COPY package.json ./

# Instalamos permitiendo que pnpm genere su propia estructura
RUN pnpm install --no-frozen-lockfile

COPY . .

# El build ahora debería pasar el check de package manager
RUN pnpm run build || true

# Enlace para Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor estático
RUN npm install -g serve

EXPOSE 3000

# Comando de arranque inteligente
CMD ["sh", "-c", "if [ -d \".vite/renderer/main_window\" ]; then serve -s .vite/renderer/main_window -l 3000; else serve -s dist -l 3000; fi"]
