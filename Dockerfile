# Usa uma imagem do servidor Nginx
FROM nginx:alpine

# Define o diretório de trabalho
WORKDIR /usr/share/nginx/html

# Remove arquivos padrão do Nginx
RUN rm -rf ./*

# Copia a pasta 'web' do seu projeto para o diretório do Nginx
COPY web/ .

# Expõe a porta 80 para acesso ao servidor
EXPOSE 80

# Inicia o Nginx
CMD ["nginx", "-g", "daemon off;"]
