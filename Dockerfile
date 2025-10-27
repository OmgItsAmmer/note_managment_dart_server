# Dockerfile for Dart server with native dependencies (drift/sqlite)
# Using Dart runtime instead of native compilation due to FFI dependencies

FROM dart:stable

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy the rest of the application
COPY . .

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV API_KEYS=test:standard:enhanced:enterprise
ENV RATE_LIMIT_MAX=100
ENV RATE_LIMIT_WINDOW_SEC=60

# Run the server using Dart runtime
CMD ["dart", "run", "bin/server.dart"]
