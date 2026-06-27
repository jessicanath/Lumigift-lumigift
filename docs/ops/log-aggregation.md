# Log Aggregation

Lumigift ships structured JSON logs (pino) to a centralized log management
system for search, alerting, and retention.

## Supported Backends

Set `LOG_BACKEND` to one of the following values:

| Backend | `LOG_BACKEND` | Required env vars |
|---|---|---|
| Datadog | `datadog` | `DD_API_KEY`, `DD_SITE` (default: `datadoghq.com`) |
| Grafana Loki | `loki` | `LOKI_URL` (e.g. `http://loki:3100`) |
| Generic HTTP (Logtail/Betterstack) | `http` | `LOG_AGGREGATION_URL`, `LOG_AGGREGATION_TOKEN` |
| AWS CloudWatch | `cloudwatch` | Use the CloudWatch agent sidecar (see below) |
| Stdout only | _(unset)_ | — |

All backends also write JSON to stdout so container log drivers (Docker,
ECS, Kubernetes) can capture logs independently.

## Environment Variables

```bash
# Select backend
LOG_BACKEND=datadog

# Log level (default: info in production, debug in dev)
LOG_LEVEL=info

# Datadog
DD_API_KEY=<your-api-key>
DD_SITE=datadoghq.com

# Loki
LOKI_URL=http://loki:3100

# Generic HTTP
LOG_AGGREGATION_URL=https://in.logtail.com
LOG_AGGREGATION_TOKEN=<source-token>
```

## Log Fields

Every log line includes:

| Field | Description |
|---|---|
| `correlationId` | UUID per request — use to trace a full request across services |
| `userId` | Authenticated user ID (when available) |
| `giftId` | Gift ID for gift-related operations |
| `service` | Service name (e.g. `gift-service`, `claim-service`) |
| `env` | `production` / `staging` / `development` |
| `app` | Always `lumigift` |

Sensitive fields (`phone`, `token`, `apiKey`, etc.) are redacted before
reaching any transport.

## Searching Logs

### By correlation ID
```
correlationId:"abc-123-..."
```

### By user
```
userId:"user_abc123"
```

### By gift
```
giftId:"gift_xyz789"
```

### Error rate spike
```
level:error | stats count() by bin(5m)
```

## Retention Policy

| Tier | Duration | Storage |
|---|---|---|
| Hot (searchable) | 90 days | Datadog / Loki / CloudWatch |
| Cold (archived) | 1 year | S3 / Glacier |

### Datadog
- Set index retention to 90 days in **Logs → Indexes**.
- Enable **Log Archives** to S3 for 1-year cold storage.

### Loki
- Set `retention_period: 2160h` (90 days) in `loki-config.yaml`.
- Configure S3 backend for object storage.

### CloudWatch
- Set log group retention to 90 days:
  ```bash
  aws logs put-retention-policy \
    --log-group-name /lumigift/app \
    --retention-in-days 90
  ```
- Export to S3 for cold storage using a scheduled Lambda or Data Firehose.

## Alerts

Configure the following alerts in your aggregation system:

| Alert | Condition | Severity |
|---|---|---|
| Error rate spike | `error` logs > 10/min for 5 min | High |
| Fatal errors | Any `fatal` log | Critical |
| Auth failures | `event:auth_failed` > 20/min | High |
| Payment failures | `event:payment_failed` > 5/min | Medium |

### Datadog Monitor (example)
```json
{
  "name": "Lumigift error rate spike",
  "type": "log alert",
  "query": "logs(\"service:lumigift status:error\").index(\"*\").rollup(\"count\").last(\"5m\") > 10",
  "message": "@slack-lumigift-alerts Error rate spike detected"
}
```

## AWS CloudWatch Agent (ECS/EC2)

Add the CloudWatch agent as a sidecar in your ECS task definition:

```json
{
  "name": "cloudwatch-agent",
  "image": "amazon/cloudwatch-agent:latest",
  "environment": [
    { "name": "CW_CONFIG_CONTENT", "value": "{\"logs\":{\"logs_collected\":{\"files\":{\"collect_list\":[{\"file_path\":\"/var/log/app/*.log\",\"log_group_name\":\"/lumigift/app\",\"log_stream_name\":\"{instance_id}\"}]}}}}" }
  ]
}
```

Or use the ECS FireLens log driver to route stdout directly to CloudWatch
without a sidecar.

## Dashboard

Key metrics to display:

- Request rate (req/min)
- Error rate (errors/min)
- P95 response time
- Gift creation rate
- Payment failure rate
- Auth failure rate
