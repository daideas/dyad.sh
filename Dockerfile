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

# Realizamos el build (sabemos que genera la web antes de fallar en el empaquetado)
RUN pnpm run build || true

# Enlace mágico para que encuentre Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# Usamos VITE PREVIEW con el host abierto para que Dokploy/Cloudflare conecten
# Este modo suele ser más compatible con apps que esperan Electron
CMD ["npx", "vite", "preview", "--port", "3000", "--host", "0.0.0.0"]
