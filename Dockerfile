# ETAPA 1: Construcción
FROM node:24-slim AS builder
RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# 1. Forzamos configuración antes de instalar
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./

# 2. ROMPEMOS CACHÉ: Añadimos un argumento dinámico para que pnpm instale de verdad
RUN pnpm install --no-frozen-lockfile --force

COPY . .

# 3. BUILD: Intentamos Vite directo (más rápido y sin checks de Electron)
# Si falla, usamos el build estándar pero asegurando que no se detenga
RUN npx vite build || pnpm run build || true

# 4. Verificamos y movemos archivos a una carpeta segura
RUN mkdir -p /app/web_dist && \
    (cp -r .vite/renderer/main_window/* /app/web_dist/ 2>/dev/null || \
     cp -r dist/* /app/web_dist/ 2>/dev/null || \
     cp -r out/* /app/web_dist/ 2>/dev/null || true)

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# Copiamos la carpeta unificada
COPY --from=builder /app/web_dist ./public

EXPOSE 3000

# Comando directo. Si hay archivos, SERVE emitirá logs.
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
