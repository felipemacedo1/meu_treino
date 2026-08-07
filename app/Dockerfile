# ----------------------------- build ---------------------------------
FROM ghcr.io/cirruslabs/flutter:3.38.6 AS build
WORKDIR /build

ARG API_BASE_URL=/api

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------------------------- runtime --------------------------------
FROM nginx:1.27-alpine
COPY --from=build /build/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
