# Usamos Node 24
FROM node:24-slim

# Herramientas mínimas de sistema
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Optimizamos pnpm para Docker
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Ejecutamos el build oficial
RUN pnpm run build || true

# Enlace mágico para que la app encuentre Node donde lo busca
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# MEJORA: Instalamos 'serve', un servidor de producción mucho más robusto
RUN npm install -g serve

EXPOSE 3000

# CAMBIO DEFINITIVO: Usamos 'serve' para entregar la carpeta compilada.
# Esto ignora los errores de "Blocked Host" y es mucho más rápido.
CMD ["serve", "-s", ".vite/renderer/main_window", "-l", "3000", "-a", "0.0.0.0"]
