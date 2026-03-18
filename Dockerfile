# Usamos Node 24
FROM node:24-slim

# Instalamos herramientas de compilación y dependencias de sistema para Dugite/Git
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Configuramos pnpm en modo hoisted
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
# Instalamos ignorando scripts que puedan fallar (como dugite)
RUN pnpm install

COPY . .

# EJECUTAMOS EL BUILD ignorando el empaquetado de Electron
# Esto crea la versión web que Dokploy puede servir
RUN pnpm run build

EXPOSE 3000
CMD ["pnpm", "run", "start"]
