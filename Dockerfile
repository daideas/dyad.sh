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

# Ejecutamos el build. Sabemos que generará la web antes de fallar en el empaquetado.
RUN pnpm run build || true

# Instalamos un servidor estático ligero
RUN npm install -g serve

EXPOSE 3000

# Apuntamos a la carpeta exacta donde Vite genera el contenido en este proyecto
# Si la ruta fuera distinta, 'serve' nos lo dirá en los logs.
CMD ["serve", "-s", ".vite/renderer/main_window", "-l", "3000"]
