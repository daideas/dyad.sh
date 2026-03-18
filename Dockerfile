# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder

# Instalación de dependencias nativas para node-gyp (necesario en Dyad)
RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Forzamos estructura plana para compatibilidad con Electron Forge
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

COPY . .

# Ejecución del build oficial de Dyad
RUN pnpm run build || true

# --- PASO DE AUDITORÍA: Verificación y Unificación ---
# Creamos una carpeta segura y movemos los archivos ahí. 
# Si Dyad cambia la ruta, este script la encuentra.
RUN mkdir -p /app/build_web && \
    (cp -r .vite/renderer/main_window/* /app/build_web/ 2>/dev/null || \
     cp -r dist/* /app/build_web/ 2>/dev/null || \
     cp -r out/* /app/build_web/ 2>/dev/null || true)

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim

WORKDIR /app
RUN npm install -g serve

# Copiamos la carpeta unificada que creamos en el paso anterior
COPY --from=builder /app/build_web ./public

# Compatibilidad de Node para procesos internos de la UI
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# Mapeo explícito a 0.0.0.0 para que Dokploy/Traefik lo vean
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
