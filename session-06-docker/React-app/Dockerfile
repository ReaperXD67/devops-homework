FROM node:24-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY src.jsx .
RUN npm run build
FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
COPY --from=build /app/dist/app.js /usr/share/nginx/html/app.js
EXPOSE 80
