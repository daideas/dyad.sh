# Cambiado a Node 24 para cumplir con los requisitos de Dyad
# Usamos Node 24 y configuramos pnpm para que sea compatible con Electron Forge
FROM node:24-slim
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Esta línea soluciona el error del node-linker
RUN pnpm config set node-linker hoisted

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install

COPY . .
RUN pnpm run build

EXPOSE 3000
CMD ["pnpm", "run", "start"]
