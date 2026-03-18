# ========================================================
# ETAPA 1: Compilación (Builder)
# ========================================================
FROM node:24-slim AS builder

# 1. Instalamos herramientas de compilación necesarias
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuramos pnpm (Modo 'hoisted' para evitar conflictos con Electron)
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

# 3. Instalación de dependencias (Cacheada para mayor velocidad)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

# 4. Copiamos el código fuente
COPY . .

# 5. Ejecutamos el Build de Vite
# Mantenemos el || true solo para que el contenedor no muera en el build 
# y podamos ver el error real después en los logs de arranque.
RUN npx vite build --emptyOutDir false || pnpm run build || true

# 6. Recolección de archivos (Unificamos posibles rutas de salida)
RUN mkdir -p /app/dist_final && \
    (cp -r .vite/renderer/main_window/* /app/dist_final/ 2>/dev/null || \
     cp -r dist/* /app/dist_final/ 2>/dev/null || \
     cp -r out/* /app/dist_final/ 2>/dev/null || true)

# 7. SEGURO ANTI-502: Si la carpeta está vacía, creamos un index de emergencia
RUN if [ ! -f /app/dist_final/index.html ]; then \
    echo "<h1>Dyad: Error de Compilación</h1><p>Vite falló. Revisa los alias @/ en vite.config.ts y los logs de Dokploy.</p>" > /app/dist_final/index.html; \
    fi

# ========================================================
# ETAPA 2: Servidor de Producción (Runtime)
# ========================================================
FROM node:24-slim
WORKDIR /app

# Instalamos el servidor estático globalmente
RUN npm install -g serve

# Copiamos solo lo necesario de la etapa anterior
COPY --from=builder /app/dist_final ./public

# IMPORTANTE: Cambiamos al puerto 4000 para no chocar con Dokploy
EXPOSE 4000

# Diagnóstico en tiempo real al arrancar el contenedor
CMD ["sh", "-c", "echo '--- VERIFICANDO ARCHIVOS ---' && ls -la ./public && echo '--- ARRANCANDO SERVIDOR EN PUERTO 4000 ---' && serve -s public -l 4000 -a 0.0.0.0"]
