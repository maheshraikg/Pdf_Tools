FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
RUN apk add --no-cache tini
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
COPY migrations ./migrations
COPY public ./public
USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s CMD wget -qO- http://127.0.0.1:3000/readyz || exit 1
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/server.js"]
