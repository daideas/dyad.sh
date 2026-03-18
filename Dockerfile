# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder
RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Configuración de Linker
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

COPY . .
RUN pnpm run build || true

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# --- EL CAMBIO RIGUROSO AQUÍ ---
# Copiamos directamente desde la ruta que el log confirmó como exitosa (#13 33.85)
# Usamos '.' para copiar el contenido de la carpeta generada a nuestra carpeta 'public'
COPY --from=builder /app/.vite/renderer/main_window ./public

# Compatibilidad de Node
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# Servimos con modo SPA (-s) en todas las interfaces (-a 0.0.0.0)
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
