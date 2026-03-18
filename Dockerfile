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

# Ejecutamos el build (sabemos que genera la web antes del error de empaquetado)
RUN pnpm run build || true

# Enlace para que la app encuentre Node.js
RUN ln -s /usr/local/bin/node /usr/bin/node || true

EXPOSE 3000

# CAMBIO CLAVE: Usamos vite preview apuntando a la carpeta de la web
# Esto suele evitar los errores de IPC al no cargar el entorno de Electron
CMD ["npx", "vite", "preview", "--outDir", ".vite/renderer/main_window", "--port", "3000", "--host", "0.0.0.0"]
