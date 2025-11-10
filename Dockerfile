FROM node:18-alpine AS build

WORKDIR /app

# Copia apenas os arquivos de dependência
COPY package*.json ./

# Garante que o yarn exista e instala dependências
RUN npm install -g yarn && yarn install

# Copia o restante do código
COPY . .

# Gera o build da aplicação
RUN yarn build

# ----------------------------- #
# Imagem final com Nginx
# ----------------------------- #
FROM nginx:alpine

# Copia os arquivos estáticos gerados para o Nginx
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80