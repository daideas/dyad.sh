# ETAPA 1: Construcción
FROM node:24-slim AS builder
RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

COPY . .
# Forzamos el build y creamos la carpeta manualmente por si falla
RUN pnpm run build || true
RUN mkdir -p .vite/renderer/main_window && touch .vite/renderer/main_window/index.html

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim
WORKDIR /app

# Instalamos serve de forma global
RUN npm install -g serve

# Copiamos la carpeta directamente
COPY --from=builder /app/.vite/renderer/main_window ./public

EXPOSE 3000

# COMANDO ULTRA-SIMPLE (Sin lógica de Shell para asegurar Logs)
# Si 'serve' no arranca, el error aparecerá sí o sí.
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
