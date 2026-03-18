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

# CREAMOS EL ENLACE DE NODE PARA EL ERROR ANTERIOR
RUN ln -s /usr/local/bin/node /usr/bin/node || true

# EXPLICACIÓN: Usamos el modo dev de Vite porque maneja mejor la 
# ausencia de Electron que la versión compilada estática
EXPOSE 3000

# Comando para saltar el error de IPC Renderer
CMD ["npx", "vite", "--port", "3000", "--host", "0.0.0.0"]
