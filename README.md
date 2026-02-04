# Slow SQL Detection with OpenTelemetry

A sample application demonstrating how to detect and monitor slow SQL queries using OpenTelemetry's spanmetrics connector.

This sample accompanies the blog post: [How to Turn Slow Queries into Actionable Reliability Metrics with OpenTelemetry](https://www.causely.ai/blog/how-to-turn-slow-queries-into-actionable-reliability-metrics-with-opentelemetry)

## Overview

This project demonstrates a practical implementation of slow SQL detection by:

1. **Emitting database spans** with OpenTelemetry semantic conventions from Go services
2. **Distilling metrics** from spans using the OpenTelemetry Collector's `spanmetrics` connector
3. **Detecting anomalies** using PromQL-based adaptive thresholds
4. **Visualizing** results in Grafana dashboards

## Prerequisites

- Docker and Docker Compose
- Ports 3001, 4317, 4318, 5432, 8080, and 8081 available

## Quick Start

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f api-user api-admin

# Stop all services
docker-compose down
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| `album-user-api` | 8080 | User-facing API with album queries |
| `album-admin-api` | 8081 | Admin API with statistics and analytics |
| `postgres` | 5432 | PostgreSQL database |
| `otelcol` | 4317/4318 | OpenTelemetry Collector (gRPC/HTTP) |
| `lgtm` | 3001 | Grafana with Loki, Tempo, and Mimir |
| `traffic` | - | Traffic generator for demo purposes |

## Testing the API

### User API (port 8080)

```bash
# Health check
curl http://localhost:8080/health

# Get album by ID (fast - indexed lookup)
curl http://localhost:8080/albums/42

# Search albums (occasionally slow - full scan)
curl "http://localhost:8080/albums/search?q=Album"

# Recent albums
curl http://localhost:8080/albums/recent?limit=10
```

### Admin API (port 8081)

```bash
# Health check
curl http://localhost:8081/health

# List albums with pagination (fast)
curl "http://localhost:8081/albums?limit=10&offset=0"

# Get statistics (occasionally slow - aggregations)
curl http://localhost:8081/albums/stats

# Analytics dashboard data
curl http://localhost:8081/albums/analytics
```

## Viewing Dashboards

1. Open Grafana at http://localhost:3001
2. Login with `admin` / `admin`
3. Navigate to **Dashboards** → **Slow SQL Dashboards**

Three dashboards are included:

- **v1**: Basic slow query metrics
- **v2**: Query impact analysis (latency × call rate)
- **v3**: Anomaly detection with adaptive thresholds

## Anomaly Detection

The sample includes PromQL-based anomaly detection rules that:

- Calculate adaptive upper/lower bounds based on historical patterns
- Detect queries that deviate significantly from their baseline
- Support both "adaptive" (short-term) and "robust" (long-term) strategies

Rules are located in `prometheus-rules/` and automatically loaded by the LGTM stack.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
