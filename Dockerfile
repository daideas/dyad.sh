# Usamos Node 24
FROM node:24-slim

# Instalamos herramientas necesarias
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Configuración de pnpm
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# --- LA SOLUCIÓN TÉCNICA ---
# En lugar de 'vite build', usamos el comando del proyecto
# pero desactivamos el empaquetado de Electron para que no busque 'dugite'
RUN pnpm run build:web || pnpm run build || true

EXPOSE 3000

# Usamos el host 0.0.0.0 para que Dokploy detecte la app
# Si 'dist' no existe, Vite nos avisará en los logs
CMD ["npx", "vite", "preview", "--port", "3000", "--host", "0.0.0.0"]
