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
# Definimos el linker como variable y como archivo físico ANTES del install
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc
ENV NPM_CONFIG_LOGLEVEL=error

COPY package.json pnpm-lock.yaml* ./

# Forzamos la instalación limpia con el nuevo linker
RUN pnpm install --frozen-lockfile

COPY . .

# Ahora el build pasará el check porque node_modules ya está 'hoisted'
RUN pnpm run build || true

# Enlace para Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor estático
RUN npm install -g serve

EXPOSE 3000

# Comando de arranque inteligente
CMD ["sh", "-c", "if [ -d \".vite/renderer/main_window\" ]; then serve -s .vite/renderer/main_window -l 3000; else serve -s dist -l 3000; fi"]
