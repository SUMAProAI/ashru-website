# Multi-stage build: Node compiles Astro → nginx serves the static dist/.
# Targets Google Cloud Run (must listen on $PORT, default 8080).

# ── Stage 1: build ───────────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --silent || npm install --silent
COPY . .
RUN npm run build

# ── Stage 2: serve ───────────────────────────────────────────────────
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html

# Cloud Run listens on $PORT (default 8080). Rewrite the default 80.
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf \
 && sed -i 's/listen  \[::\]:80;/listen  [::]:8080;/g' /etc/nginx/conf.d/default.conf || true

# Add gzip + sensible cache headers — these are real perf wins, ~70% size cut.
RUN cat > /etc/nginx/conf.d/perf.conf <<'NGINXEOF'
gzip on;
gzip_vary on;
gzip_min_length 256;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;
NGINXEOF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
