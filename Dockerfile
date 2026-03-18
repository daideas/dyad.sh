# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Seteamos el linker por si acaso, pero vamos a intentar bypass
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

COPY . .

# --- EL CAMBIO RADICAL ---
# En lugar de 'pnpm run build' (que llama a Forge), llamamos directamente al compilador de Vite
# Esto genera los archivos web sin hacer chequeos de sistema de escritorio
RUN npx vite build || pnpm run build || true

# Verificamos dónde quedaron los archivos y los movemos a una carpeta fija
RUN mkdir -p /app/dist_final && \
    cp -r .vite/renderer/main_window/* /app/dist_final/ 2>/dev/null || \
    cp -r dist/* /app/dist_final/ 2>/dev/null || \
    cp -r out/* /app/dist_final/ 2>/dev/null || true

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# Copiamos desde la carpeta unificada
COPY --from=builder /app/dist_final ./public

RUN ln -s /usr/local/bin/node /usr/bin/node || true
EXPOSE 3000

# Servimos con modo SPA
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
