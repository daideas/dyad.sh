# Usamos Node 24
FROM node:24-slim

# Herramientas mínimas
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Ejecutamos el build
RUN pnpm run build || true

# Enlace mágico para Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# CAMBIO CLAVE: Añadimos --allowedHosts para que Vite acepte tu dominio
CMD ["npx", "vite", "preview", "--outDir", ".vite/renderer/main_window", "--port", "3000", "--host", "0.0.0.0", "--allowedHosts", "dyad.daidea.es"]
