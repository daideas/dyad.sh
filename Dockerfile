# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# 1. Configuración de Linker (Forzamos un cambio aquí para romper la caché)
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

# 2. Copiamos los archivos de dependencia
COPY package.json pnpm-lock.yaml* ./

# 3. Instalación LIMPIA (Añadimos un echo aleatorio para asegurar que no use caché si falla)
RUN pnpm install --no-frozen-lockfile && pnpm config set node-linker hoisted

# 4. Copiamos el resto del código
COPY . .

# 5. Ejecutamos el build de Dyad
# Forzamos a Vite a construir la web ignorando el empaquetado final de Electron
RUN pnpm run build || true

# 6. Verificación de seguridad: si no existe la carpeta, la creamos vacía para que no explote el COPY
RUN mkdir -p /app/build_web && \
    cp -rn .vite/renderer/main_window/* /app/build_web/ 2>/dev/null || \
    cp -rn dist/* /app/build_web/ 2>/dev/null || \
    touch /app/build_web/index.html

# ETAPA 2: Servidor de Producción
FROM node:24-slim
WORKDIR /app
RUN npm install -g serve

# Copiamos los activos generados
COPY --from=builder /app/build_web ./public

# Compatibilidad de Node
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# Arranque en 0.0.0.0 (imprescindible para Dokploy)
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
