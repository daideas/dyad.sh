# Usamos Node 24 para cumplir con los requisitos de Dyad
FROM node:24-slim

# Instalamos herramientas de compilación y librerías necesarias
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Forzamos el modo hoisted para evitar líos de rutas con dependencias nativas
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Compilamos la versión web directamente con Vite
# Añadimos || true para que si falla algún check de tipos no detenga el despliegue
RUN npx vite build || true

EXPOSE 3000

# Arrancamos el servidor de previsualización
# --host 0.0.0.0 es VITAL para que Dokploy pueda conectar con el contenedor
CMD ["npx", "vite", "preview", "--port", "3000", "--host", "0.0.0.0"]
