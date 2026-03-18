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

# Ejecutamos el build oficial. Ignoramos el fallo final de Electron.
RUN pnpm run build || true

EXPOSE 3000

# El cambio CRUCIAL: Apuntamos a la carpeta donde Vite realmente guardó la web
# Dyad usa electron-forge + vite, por lo que el output está en .vite/renderer/main_window
CMD ["npx", "vite", "preview", "--outDir", ".vite/renderer/main_window", "--port", "3000", "--host", "0.0.0.0"]
