# Multi-stage Dockerfile for optimized production builds

# Stage 1: Build and resolve dependencies
FROM dart:stable AS build
WORKDIR /app

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy source code
COPY . .

# Compile the application to native code
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Create minimal runtime image
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy compiled binary and necessary files
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/openapi.yaml /app/openapi.yaml
COPY --from=build /app/public /app/public

WORKDIR /app

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV API_KEYS=test:standard:enhanced:enterprise
ENV RATE_LIMIT_MAX=60
ENV RATE_LIMIT_WINDOW_SEC=60

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/app/bin/server"] || exit 1

# Run the server
CMD ["/app/bin/server"]
