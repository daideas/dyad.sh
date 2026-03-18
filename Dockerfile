# Usamos Node 24 slim para un contenedor ligero pero potente
FROM node:24-slim

# Instalamos dependencias de compilación necesarias para paquetes nativos
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Preparamos pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# --- CONFIGURACIÓN DE ESTRUCTURA ---
# Forzamos el modo 'hoisted' para que Electron Forge no falle
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc
# Reducimos el ruido de logs pero mantenemos errores críticos
ENV NPM_CONFIG_LOGLEVEL=warn 

# Copiamos solo lo necesario para instalar dependencias (aprovecha la caché de Docker)
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

# Copiamos el resto del código del proyecto
COPY . .

# Re-aseguramos el archivo .npmrc por si el COPY lo sobrescribió
RUN echo "node-linker=hoisted" > .npmrc

# Ejecutamos el build. '|| true' es vital porque el empaquetado de .deb/.rpm 
# fallará en Docker, pero la web se genera justo antes.
RUN pnpm run build || true

# Enlace simbólico para que los scripts internos encuentren Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos 'serve', el estándar de la industria para apps estáticas
RUN npm install -g serve

EXPOSE 3000

# --- COMANDO DE ARRANQUE INTELIGENTE (Solución al 404) ---
# Este comando busca dónde quedó el index.html y sirve esa carpeta.
CMD ["sh", "-c", "TARGET_DIR=$(find . -name index.html -not -path '*/node_modules/*' | head -n 1 | xargs dirname); \
    if [ -n \"$TARGET_DIR\" ]; then \
        echo \"🚀 Dyad detectado en: $TARGET_DIR\"; \
        serve -s \"$TARGET_DIR\" -l 3000 -a 0.0.0.0; \
    else \
        echo \"❌ ERROR: No se encontró index.html para servir\"; \
        exit 1; \
    fi"]
