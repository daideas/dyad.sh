# Usamos Node 24
FROM node:24-slim

# Instalamos Python y herramientas de compilación necesarias para better-sqlite3
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Configuramos pnpm para modo hoisted
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .
RUN pnpm run build

EXPOSE 3000
CMD ["pnpm", "run", "start"]
