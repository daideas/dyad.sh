# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# 1. Forzamos la configuración ANTES de cualquier copia
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

# 2. Copiamos los archivos de proyecto
COPY package.json pnpm-lock.yaml* ./

# 3. INSTALACIÓN LIMPIA (Eliminamos la caché previa)
# Usamos --force para asegurar que los enlaces simbólicos se conviertan en carpetas reales (hoisted)
RUN pnpm install --no-frozen-lockfile --force

COPY . .

# 4. El Build ahora SÍ encontrará los módulos correctos y creará la carpeta .vite
RUN pnpm run build || true

# ETAPA 2: Servidor (Runtime)
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# 5. Recuperamos los archivos (usamos un comodín por si la ruta varía ligeramente)
# Si Dyad no generó .vite, el build fallará aquí dándonos un error real, no un 502
COPY --from=builder /app/.vite/renderer/main_window ./public

RUN ln -s /usr/local/bin/node /usr/bin/node || true
EXPOSE 3000

CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
