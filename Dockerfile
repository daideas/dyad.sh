# ========================================================
# ETAPA 1: Compilación (Builder)
# ========================================================
FROM node:24-slim AS builder

# Instalamos herramientas mínimas necesarias
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Preparamos pnpm y configuramos el linker para evitar errores de Electron
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
ENV PNPM_NODE_LINKER=hoisted
RUN echo "node-linker=hoisted" > .npmrc

# Instalación de dependencias
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

# Copiamos el código y ejecutamos el build
COPY . .

# Intentamos el build de Vite. 
# Si falla, el contenedor seguirá vivo para que podamos auditar los archivos.
RUN npx vite build --emptyOutDir false || pnpm run build || true

# Recolección inteligente de archivos compilados
RUN mkdir -p /app/dist_final && \
    (cp -r .vite/renderer/main_window/* /app/dist_final/ 2>/dev/null || \
     cp -r dist/* /app/dist_final/ 2>/dev/null || \
     cp -r out/* /app/dist_final/ 2>/dev/null || true)

# Seguro anti-vaciado: Si Vite no generó nada, creamos el aviso de error.
RUN if [ ! -f /app/dist_final/index.html ]; then \
    echo "<h1>Dyad: Error de Compilación</h1><p>Vite no generó archivos. Revisa los alias @/ en vite.config.ts.</p>" > /app/dist_final/index.html; \
    fi

# ========================================================
# ETAPA 2: Servidor de Producción (Runtime)
# ========================================================
FROM node:24-slim
WORKDIR /app

# Instalamos el servidor estático
RUN npm install -g serve

# Copiamos los archivos generados
COPY --from=builder /app/dist_final ./public

# EXPOSE 4000: Cambiamos al 4000 porque Dokploy ya usa el 3000
EXPOSE 4000

# Comando de arranque con diagnóstico integrado
# Esto imprimirá en los logs de Dokploy qué está pasando exactamente.
CMD ["sh", "-c", "echo '--- AUDITORIA DE ARRANQUE ---' && ls -la ./public && echo '--- INICIANDO SERVIDOR EN PUERTO 4000 ---' && serve -s public -l 4000 -a 0.0.0.0"]
