# ashru.dev — static marketing website, served by nginx on Google Cloud Run.
#
# This repo (SUMAProAI/ashru-website) holds ONLY the website. The format
# itself — spec, reference parsers, SDK, tutorials — lives in a separate
# public repo: github.com/ashru-format/ashru-format.
#
# We bundle a copy of parsers/javascript/ashru.js inside this repo so the
# converter can import it locally (zero runtime dependency on the format
# repo or any CDN). Periodically sync via tools/sync-parser.sh.
#
# Build context = repo root. Submit:
#   gcloud builds submit --config cloudbuild.yaml --project quadframe .

FROM nginx:1.27-alpine

# Static assets at the web root
COPY index.html converter.html style.css favicon.svg /usr/share/nginx/html/

# Bundled JS parser the converter imports from "../parsers/javascript/ashru.js"
RUN mkdir -p /usr/share/nginx/html/parsers/javascript
COPY parsers/javascript/ashru.js /usr/share/nginx/html/parsers/javascript/ashru.js

# Cloud Run listens on $PORT (default 8080); nginx defaults to 80.
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf \
 && sed -i 's/listen  \[::\]:80;/listen  [::]:8080;/g' /etc/nginx/conf.d/default.conf || true

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
