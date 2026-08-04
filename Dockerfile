# syntax=docker/dockerfile:1

# ---------- Build stage: compile the Flutter web bundle ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Resolve dependencies first so this layer caches unless pubspec changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source and build.
COPY . .

# Supabase config is optional at build time — if these args are omitted the
# app falls back to the public defaults baked into lib/config/supabase_config.dart.
# The anon key is a public, RLS-protected client key (safe to pass here).
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""

# Only pass --dart-define when an arg is actually provided, so an empty arg
# can't override the in-code default with an empty string. base-href stays "/"
# because nginx serves from the domain root (unlike the /Coinsight/ Pages path).
RUN set -eu; \
    EXTRA=""; \
    [ -n "$SUPABASE_URL" ] && EXTRA="$EXTRA --dart-define=SUPABASE_URL=$SUPABASE_URL"; \
    [ -n "$SUPABASE_ANON_KEY" ] && EXTRA="$EXTRA --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"; \
    flutter build web --release --no-tree-shake-icons $EXTRA

# ---------- Runtime stage: serve the static bundle with nginx ----------
FROM nginx:alpine AS runtime

# Static assets.
COPY --from=build /app/build/web /usr/share/nginx/html

# SPA fallback: unknown paths (deep links / refreshes) resolve to index.html.
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
