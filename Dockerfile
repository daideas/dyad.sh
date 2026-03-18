# ETAPA 1: Construcción (Builder)
FROM node:24-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Configuración técnica de pnpm para Electron Forge
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

COPY . .
# Volvemos a asegurar el linker después del copy
RUN echo "node-linker=hoisted" > .npmrc

# Ejecutamos el build. Solo nos interesan los archivos generados.
RUN pnpm run build || true

# ETAPA 2: Servidor de Producción (Final)
FROM node:24-slim

WORKDIR /app
RUN npm install -g serve

# PASO CLAVE: Copiamos SOLO los archivos web generados de la etapa anterior.
# Buscamos en las dos rutas posibles donde Dyad guarda la web:
COPY --from=builder /app/.vite/renderer/main_window ./public 2>/dev/null || \
    COPY --from=builder /app/dist ./public 2>/dev/null || \
    COPY --from=builder /app/out ./public 2>/dev/null || true

# Enlace simbólico de Node por seguridad de compatibilidad
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# Servimos la carpeta 'public' que ahora contiene los archivos estáticos
# Usamos 0.0.0.0 para que Dokploy detecte la interfaz de red correctamente
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
