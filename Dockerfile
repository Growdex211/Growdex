# syntax=docker/dockerfile:1

FROM node:24-alpine AS builder
WORKDIR /app

ARG VITE_API_URL=https://api.growdex.ai
ARG VITE_WAITLIST_KEY
ENV VITE_API_URL=$VITE_API_URL \
    VITE_WAITLIST_KEY=$VITE_WAITLIST_KEY

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund

COPY . .
RUN npm run build

FROM nginx:1.29-alpine AS runner
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
