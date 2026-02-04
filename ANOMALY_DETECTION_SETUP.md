# PromQL Anomaly Detection Integration

This document explains how the Grafana PromQL Anomaly Detection framework has been integrated into the slow SQL monitoring setup.

## What Was Added

1. **Prometheus Rules Directory** (`prometheus-rules/`):
   - `adaptive.yml` - Base adaptive anomaly detection rules
   - `robust.yml` - Base robust anomaly detection rules  
   - `slowsql-anomaly-tagging.yml` - Recording rules that tag slow SQL metrics for anomaly detection

2. **Docker Compose Updates**:
   - Rules are mounted into the `lgtm` container at `/etc/prometheus/rules` and `/prometheus/rules`

## How It Works

The integration follows this flow:

1. **Metrics Generation**: The `spanmetrics` connector generates metrics like:
   - `traces_span_metrics_duration_milliseconds_bucket` (histogram)
   - `traces_span_metrics_calls_total` (counter)

2. **Tagging**: Recording rules in `slowsql-anomaly-tagging.yml` create new metrics tagged with:
   - `anomaly_name`: Unique identifier (e.g., `slowsql_latency_p95`)
   - `anomaly_type`: Type (`latency` or `requests`)
   - `anomaly_strategy`: Detection algorithm (`adaptive` or `robust`)

3. **Anomaly Detection**: The base rules (`adaptive.yml`, `robust.yml`) automatically generate:
   - Upper and lower anomaly bands
   - Alert metrics when thresholds are crossed

## Verification Steps

### 1. Start the Stack

```bash
cd sample-app
docker-compose up -d
```

### 2. Wait for Rules to Load

Prometheus/Mimir needs a few moments to discover and load the rules. Wait 1-2 minutes after startup.

### 3. Check Recording Rules

Open Grafana (http://localhost:3000) and navigate to **Explore** → **Prometheus**:

```promql
# Check if tagged metrics exist
anomaly:slowsql:latency:p95

# Should return time series with labels:
# - anomaly_name="slowsql_latency_p95"
# - anomaly_type="latency"
# - anomaly_strategy="adaptive"
# - service_name, db_system, db_name, span_name
```

### 4. Check Anomaly Bands

```promql
# Upper bound
anomaly:adaptive:band:upper{anomaly_name="slowsql_latency_p95"}

# Lower bound  
anomaly:adaptive:band:lower{anomaly_name="slowsql_latency_p95"}
```

### 5. Check Alerts

```promql
# Anomaly alerts
anomaly:adaptive:alert{anomaly_name="slowsql_latency_p95"}
```

## Troubleshooting

### Rules Not Appearing

If the rules don't appear in Prometheus:

1. **Verify rules are mounted**:
   ```bash
   docker-compose exec lgtm ls -la /etc/prometheus/rules
   docker-compose exec lgtm ls -la /prometheus/rules
   ```

2. **Check Mimir/Prometheus logs**:
   ```bash
   docker-compose logs lgtm | grep -i "rule\|prometheus\|mimir"
   ```

3. **Note**: The `otel-lgtm` image uses Mimir internally. If rules don't auto-load, you may need to:
   - Configure Mimir ruler via Grafana's UI (if available)
   - Use Grafana's recording rules API
   - Check if there's an environment variable to configure rule paths

### No Data in Anomaly Metrics

1. **Verify source metrics exist**:
   ```promql
   traces_span_metrics_duration_milliseconds_bucket{db_system!=""}
   ```

2. **Check recording rule evaluation**:
   - In Grafana Explore, check if `anomaly:slowsql:latency:p95` returns data
   - If not, verify the PromQL in `slowsql-anomaly-tagging.yml` matches your metric names

3. **Wait for training period**: Anomaly detection requires 24-26 hours of data for full accuracy

## Using in Dashboards

You can add anomaly bands to any time series panel:

**Example Panel Query**:
```promql
# Main metric
anomaly:slowsql:latency:p95{service_name="album-user-api"}

# Overlay: Upper bound (add as second query)
anomaly:adaptive:band:upper{anomaly_name="slowsql_latency_p95", service_name="album-user-api"}

# Overlay: Lower bound (add as third query)
anomaly:adaptive:band:lower{anomaly_name="slowsql_latency_p95", service_name="album-user-api"}
```

In Grafana:
1. Add the main query
2. Add the upper bound query, set visualization to "Bands" or "Area" with transparency
3. Add the lower bound query, set visualization to "Bands" or "Area" with transparency

## Available Anomaly Metrics

The tagging rules create these metrics:

| Metric | Type | Strategy | Description |
|--------|------|----------|-------------|
| `anomaly:slowsql:latency:p95` | latency | adaptive | 95th percentile query latency |
| `anomaly:slowsql:query:rate` | requests | adaptive | Query rate (queries/sec) |
| `anomaly:slowsql:duration:avg` | latency | adaptive | Average query duration |
| `anomaly:slowsql:latency:p95:robust` | latency | robust | 95th percentile (robust strategy) |
| `anomaly:slowsql:query:rate:robust` | requests | robust | Query rate (robust strategy) |

## Strategy Comparison

- **Adaptive** (default): Best for normally distributed metrics, quick detection of short-term changes
- **Robust**: Best for spiky/non-normal metrics, better for long-term trend detection

## Next Steps

1. **Create a dashboard** that visualizes slow SQL queries with anomaly bands
2. **Set up alerts** using `anomaly:adaptive:alert` metrics
3. **Tune thresholds** by adjusting multipliers in `adaptive.yml` or `robust.yml` if needed

## References

- [PromQL Anomaly Detection Framework](https://github.com/grafana/promql-anomaly-detection)
- [Framework Documentation](https://github.com/grafana/promql-anomaly-detection/blob/main/rules/README.md)
