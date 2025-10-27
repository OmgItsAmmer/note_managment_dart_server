# Dart Backend Tech Test

A RESTful API server built with Dart and Shelf framework for managing notes with
authentication, rate limiting, and feature flags.

## Features

- **Notes CRUD API**: Create, read, update, and delete notes with pagination
- **Authentication**: API key-based authentication with configurable keys
- **Rate Limiting**: Per-API-key rate limiting with configurable limits
- **Feature Flags**: Tier-based feature access (Sandbox, Standard, Enhanced,
  Enterprise)
- **Request Logging**: Structured JSON logging with response times
- **Health Check**: Basic health endpoint for monitoring
- **API Documentation**: OpenAPI 3.0 spec with interactive Swagger UI
- **Comprehensive Tests**: 24 tests covering all functionality
- **Docker Support**: Containerized deployment ready

## API Endpoints

### Documentation

- `GET /docs` - Interactive Swagger UI documentation
- `GET /openapi.yaml` - OpenAPI 3.0 specification

### Health Check

- `GET /health` - Returns "ok" (no auth required)

### Feature Flags

- `GET /v1/feature-flags` - Returns available features based on API key tier

### Notes

- `GET /v1/notes` - List notes with pagination (`?page=1&limit=20`)
- `POST /v1/notes` - Create a new note
- `GET /v1/notes/<id>` - Get specific note
- `PUT /v1/notes/<id>` - Update note
- `DELETE /v1/notes/<id>` - Delete note

## Configuration

### Environment Variables

- `PORT` - Server port (default: 8080)
- `API_KEYS` - Colon-separated list of valid API keys (e.g., "key1:key2:key3")
- `RATE_LIMIT_MAX` - Max requests per window (default: 60)
- `RATE_LIMIT_WINDOW_SEC` - Rate limit window in seconds (default: 60)

### API Key Tiers

API keys determine feature access:

- **Sandbox**: Basic notes CRUD only
- **Standard**: Notes CRUD + OAuth
- **Enhanced**: Standard + Advanced Reports
- **Enterprise**: Enhanced + SSO/SAML

Key tier detection by suffix: `enterprise`, `enhanced`, `standard`, or default
to `Sandbox`.

## Getting Started

### Prerequisites

- Dart SDK 3.4.0 or higher

### Installation

```bash
# Install dependencies
dart pub get

# Run the server
dart run bin/server.dart
```

### Docker

```bash
# Build image
docker build -t dart-backend .

# Run container
docker run -p 8080:8080 -e API_KEYS="test:standard:enhanced:enterprise" dart-backend
```

## Testing

```bash
# Run all tests
dart test

# Run tests with detailed output
dart test --reporter expanded

# Run performance test
dart test test/performance_test.dart
```

**Test Coverage:** 24 comprehensive tests including:

- Auth middleware tests
- Rate limiting tests
- Feature flags tests
- Notes CRUD tests
- Validation tests
- Logging tests
- Performance benchmarks

## Project Structure

```
lib/src/
├── controllers/
│   └── notes_controller.dart    # Notes CRUD operations
├── middleware/
│   ├── auth.dart                # API key authentication
│   ├── logging.dart             # Request/response logging
│   └── rate_limit.dart          # Rate limiting
├── models/
│   └── note.dart                # Note data model
└── services/
    └── feature_flags.dart       # Feature flag service
```

## Example Usage

### Create a Note

```bash
curl -X POST http://localhost:8080/v1/notes \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"title": "My Note", "content": "Note content"}'
```

### List Notes

```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:8080/v1/notes?page=1&limit=10
```

### Get Feature Flags

```bash
curl -H "X-API-Key: standard-key" \
  http://localhost:8080/v1/feature-flags
```

## Performance

Based on 100 requests to the list endpoint:

- **P50 Latency:** 3.00 ms
- **P95 Latency:** 5.41 ms
- **P99 Latency:** 33.12 ms

See `REPORT.md` for detailed performance analysis.

## Documentation

This project includes:

- **REPORT.md**: Comprehensive implementation report with architecture
  decisions, tradeoffs, and analysis
- **OpenAPI Spec**: Machine-readable API specification
- **Swagger UI**: Interactive API documentation at `/docs`

## Assignment Completion

✅ **Core Requirements (All Complete)**

- Notes CRUD with validation and pagination
- API key authentication via X-API-Key header
- Per-key rate limiting (fixed window algorithm)
- Feature flags with 4 tiers
- Structured JSON logging
- Comprehensive error handling
- 24 comprehensive tests (unit + integration)
- Performance benchmarking (P95: 5.41ms)

✅ **Bonus Features**

- OpenAPI 3.0 specification
- Interactive Swagger UI documentation

See `REPORT.md` for detailed documentation of architecture, design decisions,
and tradeoffs.
"# note_managment_dart_server" 
