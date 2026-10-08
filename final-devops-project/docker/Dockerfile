FROM node:24-alpine AS test
WORKDIR /app
COPY application/package*.json ./
RUN npm ci --ignore-scripts
COPY application/ ./
RUN npm run build && npm test

FROM node:24-alpine
# The runtime uses only Node's standard library. Omit npm and Yarn, including
# their unused transitive dependencies, from the deployed filesystem.
RUN rm -rf /usr/local/lib/node_modules /opt/yarn* /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/yarnpkg
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=test --chown=node:node /app/server.js ./server.js
USER node
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s CMD node -e "fetch('http://127.0.0.1:8080/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "server.js"]
