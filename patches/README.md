# OpenMeter Patches

This directory contains patches and modifications made to the OpenMeter Helm chart to support external database configurations.

## Patches Applied

### Svix External Database Support

**Files Modified:**

- `deploy/charts/openmeter/templates/svix.yaml`
- `deploy/charts/openmeter/values.yaml`

**Changes:**

- Added conditional logic for external PostgreSQL database connections
- Added conditional logic for external Redis connections
- Maintained backward compatibility with bundled services
- Added new configuration options for external DSNs

### Key Features

1. **External PostgreSQL Support**: Configure Svix to use external PostgreSQL via `svix.database.dsn`
2. **External Redis Support**: Configure Svix to use external Redis via `svix.redis.dsn`
3. **Backward Compatibility**: Existing deployments continue to work without changes
4. **Production Ready**: Enables deployment with managed database services

## Configuration Examples

### External Services Configuration

```yaml
svix:
  enabled: true
  database:
    dsn: "postgres://username:password@your-rds-endpoint:5432/svix?sslmode=require"
  redis:
    dsn: "redis://your-elasticache-endpoint:6379"
```

### Bundled Services (Default)

```yaml
svix:
  enabled: true
  # Uses internal PostgreSQL and Redis pods
```
