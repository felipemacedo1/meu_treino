# ----------------------------- build ---------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# cache das dependencias
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package

# ---------------------------- runtime --------------------------------
FROM eclipse-temurin:21-jre
WORKDIR /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/target/app.jar app.jar
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"

HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=10 \
  CMD curl -fsS http://localhost:8080/api/health || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
