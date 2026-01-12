# Advanced GCP Logging Queries

## Filter by Resource Type

### Cloud Run
```
resource.type="cloud_run_revision"
resource.labels.service_name="SERVICE"
resource.labels.location="REGION"
```

### GKE
```
resource.type="k8s_container"
resource.labels.cluster_name="CLUSTER"
resource.labels.namespace_name="NAMESPACE"
resource.labels.pod_name:"POD_PREFIX"
```

### Cloud SQL
```
resource.type="cloudsql_database"
resource.labels.database_id="PROJECT:INSTANCE"
```

### Cloud Functions
```
resource.type="cloud_function"
resource.labels.function_name="FUNCTION"
```

## Complex Filters

### Errors excluding known noise
```
severity>=ERROR
AND NOT textPayload:"health check"
AND NOT textPayload:"readiness probe"
AND NOT jsonPayload.message:"expected disconnect"
```

### Slow requests (latency > 1s)
```
httpRequest.latency>"1s"
AND httpRequest.status>=200
AND httpRequest.status<300
```

### Failed authentication
```
protoPayload.authenticationInfo.principalEmail:*
AND protoPayload.status.code!=0
```

## Aggregation Patterns

### Error rate per minute
```bash
gcloud logging read 'severity>=ERROR' --format=json | \
  jq -r '.[] | .timestamp[:16]' | \
  sort | uniq -c
```

### Top error sources
```bash
gcloud logging read 'severity>=ERROR' --format=json | \
  jq -r '.[] | .resource.labels.service_name // .resource.type' | \
  sort | uniq -c | sort -rn
```
