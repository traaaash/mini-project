FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install pm2 -g && npm install

COPY . .
EXPOSE 3000
CMD ["pm2-runtime", "index.js"]
