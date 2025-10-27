# Quick Answers & Commands

## Running the Server

### Standard Mode (In-Memory)

```bash
dart pub get
dart run bin/server.dart
```

### With SQLite Persistence

```bash
USE_PERSISTENCE=true dart run bin/server.dart
```

### With Docker

```bash
# Build
docker build -t dart-tech-test:latest .

# Run
docker run -p 8080:8080 -e USE_PERSISTENCE=true dart-tech-test:latest
```

## Testing

```bash
# All tests
dart test

# Unit tests only (no server needed)
dart test --exclude-tags=integration

# Performance test
dart test test/performance_test.dart
```

## Accessing the API

### Health Check

```bash
curl http://localhost:8080/health
```

### Swagger UI

Open browser: http://localhost:8080/docs

### OpenAPI Spec

```bash
curl http://localhost:8080/openapi.yaml
```

### Create a Note

```bash
curl -X POST http://localhost:8080/v1/notes \
  -H "X-API-Key: test" \
  -H "Content-Type: application/json" \
  -d '{"title": "My Note", "content": "Note content"}'
```

### List Notes

```bash
curl http://localhost:8080/v1/notes?page=1&limit=10 \
  -H "X-API-Key: test"
```

### Get Feature Flags

```bash
curl http://localhost:8080/v1/feature-flags \
  -H "X-API-Key: enterprise"
```

## CI/CD

GitHub Actions workflow runs automatically on push/PR to `main` or `develop`
branches.

Workflow includes:

- Dependency installation
- Code formatting check
- Static analysis
- Test execution
- Docker build and health check

See: `.github/workflows/test.yml`

## Environment Variables

| Variable                | Default                             | Description              |
| ----------------------- | ----------------------------------- | ------------------------ |
| `PORT`                  | `8080`                              | Server port              |
| `API_KEYS`              | `test:standard:enhanced:enterprise` | Colon-separated API keys |
| `RATE_LIMIT_MAX`        | `60`                                | Max requests per window  |
| `RATE_LIMIT_WINDOW_SEC` | `60`                                | Window size in seconds   |
| `USE_PERSISTENCE`       | `false`                             | Enable SQLite database   |

## API Keys & Tiers

- `test` or any key with "sandbox" → Sandbox tier
- Keys with "standard" → Standard tier
- Keys with "enhanced" → Enhanced tier
- Keys with "enterprise" → Enterprise tier

## Notes

- Database file created at: `notes.db` (when persistence enabled)
- In-memory mode: data lost on restart
- SQLite mode: data persists across restarts
- Rate limits are per API key and reset after window expires
