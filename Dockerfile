# Usamos Node 24
FROM node:24-slim

# Instalamos herramientas mínimas
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

# FORZAMOS EL BUILD DE VITE MANUALMENTE (Esto crea la carpeta 'dist')
RUN npx vite build

# Enlace para Node.js (por el error anterior)
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor
RUN npm install -g serve

EXPOSE 3000

# Servimos la carpeta 'dist' que acabamos de crear con el build manual
CMD ["serve", "-s", "dist", "-l", "3000", "-a", "0.0.0.0"]
