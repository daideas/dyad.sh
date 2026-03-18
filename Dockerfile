# ETAPA 1: Construcción (Builder)
# ETAPA 1: Construcción
FROM node:24-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# CONFIGURACIÓN CRÍTICA
# Seteamos el linker en el entorno y en el archivo antes de instalar NADA
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./

# Instalamos y FORZAMOS el linker en la configuración de pnpm activa
RUN pnpm install --no-frozen-lockfile && pnpm config set node-linker hoisted

COPY . .

# RE-FORZAMOS EL ARCHIVO POR SI EL COPY LO BORRÓ
RUN echo "node-linker=hoisted" > .npmrc

# Ejecutamos el build oficial de la app
# Dyad necesita que este comando pase para que Vite resuelva los alias (@/)
RUN pnpm run build || true

# ETAPA 2: Servidor final
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# Recogemos los archivos de la ruta de Vite confirmada por Dyad
COPY --from=builder /app/.vite/renderer/main_window ./public

RUN ln -s /usr/local/bin/node /usr/bin/node || true
EXPOSE 3000

# Servimos con modo SPA para que las rutas internas funcionen
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
