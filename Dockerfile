# ========================================================
# ETAPA 1: Compilación (Builder)
# Optimizamos para que Electron Forge no bloquee el proceso
# ========================================================
FROM node:24-slim AS builder

# Instalamos dependencias de sistema necesarias para Node-Gyp y Dyad
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Preparamos pnpm (el motor de Dyad)
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# CONFIGURACIÓN DE SEGURIDAD PARA PNPM
# Forzamos el modo 'hoisted' para que los módulos sean planos
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

# Instalación de paquetes (Capa cacheada si no cambia package.json)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

# Copiamos el código fuente completo
COPY . .

# EJECUCIÓN DEL BUILD 
# Intentamos compilar la web. Si falla por errores de código (@/alias), 
# el '|| true' permite que el Docker continúe para darnos diagnóstico.
RUN npx vite build --emptyOutDir false || pnpm run build || true

# RECOLECCIÓN DE ARCHIVOS (Auditoría de rutas)
# Dyad puede generar archivos en .vite, dist o out. Los unificamos.
RUN mkdir -p /app/dist_final && \
    (cp -r .vite/renderer/main_window/* /app/dist_final/ 2>/dev/null || \
     cp -r dist/* /app/dist_final/ 2>/dev/null || \
     cp -r out/* /app/dist_final/ 2>/dev/null || true)

# SEGURO ANTI-502: Si no hay index.html, creamos uno de emergencia.
# Esto mantiene el contenedor encendido y nos permite ver logs.
RUN if [ ! -f /app/dist_final/index.html ]; then \
    echo "<h1>Dyad: Error de Compilación</h1><p>Vite no pudo generar los archivos por errores de rutas internas (@/atoms). El servidor está vivo, pero el código necesita ajustes.</p>" > /app/dist_final/index.html; \
    fi

# ========================================================
# ETAPA 2: Servidor de Producción (Runtime)
# ========================================================
FROM node:24-slim
WORKDIR /app

# Instalamos el servidor estático 'serve'
RUN npm install -g serve

# Copiamos los archivos finales del Builder
COPY --from=builder /app/dist_final ./public

# Aseguramos compatibilidad de ejecución
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Puerto que Dokploy debe mapear
EXPOSE 3000

# ARRANQUE DEFINITIVO
# -s: Modo SPA (Single Page Application)
# -l 3000: Puerto de escucha
# -a 0.0.0.0: Escucha externa (Crucial para que el 502 desaparezca)
CMD ["serve", "-s", "public", "-l", "3000", "-a", "0.0.0.0"]
