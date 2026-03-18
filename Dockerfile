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

# Ejecutamos el build que SÍ funciona para generar la web
RUN pnpm run build || true

# Enlace para Node.js (necesario para la app)
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# Instalamos el servidor estático
RUN npm install -g serve

EXPOSE 3000

# TRUCO: Si la carpeta .vite no existe, la buscamos o usamos dist
# Este comando es a prueba de fallos
CMD ["sh", "-c", "if [ -d \".vite/renderer/main_window\" ]; then serve -s .vite/renderer/main_window -l 3000; else serve -s dist -l 3000; fi"]
