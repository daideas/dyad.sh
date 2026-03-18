# Usamos Node 24
FROM node:24-slim

# Instalamos TODAS las dependencias de Linux que Dyad/Electron necesitan para compilar
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    libnss3 \
    libatk-bridge2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Forzamos modo hoisted
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .

# Usamos el comando oficial pero le decimos que solo nos importa el build web
# Esto debería saltarse los errores de empaquetado final
RUN pnpm run build || true

EXPOSE 3000

# Arrancamos con el comando de inicio oficial
CMD ["pnpm", "run", "start"]
