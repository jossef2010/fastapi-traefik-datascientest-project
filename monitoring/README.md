# Monitoring (Prometheus + Grafana)

Dieses Setup ist bewusst minimal und für lokale Entwicklung gedacht. Es basiert auf Konfiguration statt manueller UI-Klicks.

## Enthalten

- Prometheus mit statischer Konfiguration (`monitoring/prometheus/prometheus.yml`)
- Grafana mit Provisioning für
  - Prometheus-Datasource
  - vordefiniertes Dashboard `Backend Overview`
- FastAPI-Metrik-Endpunkt unter `GET /metrics`

## Starten

Aus dem Repo-Root:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

## Prüfen

1. **Backend-Metriken erreichbar**

```bash
curl http://localhost:8000/metrics
```

Erwartung: Text im Prometheus-Format mit Metriken wie `app_http_requests_total`.

2. **Prometheus läuft und scrapt**

- UI: http://localhost:9090/targets
- Erwartung: Jobs `prometheus` und `backend` stehen auf `UP`.

3. **Grafana läuft und Dashboard ist vorprovisioniert**

- UI: http://localhost:3000
- Login: `admin` / `admin`
- Erwartung: Dashboard **FastAPI / Backend Overview** ist direkt verfügbar.

## Hinweise

- Das Dashboard zeigt u. a. die Request-Rate nach Route/Status, Gesamtanzahl Requests und Backend-Uptime.
- Zugangsdaten sind lokale Development-Defaults und sollten außerhalb lokal/dev angepasst werden.
