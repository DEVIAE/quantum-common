# Quantum ELK - Dashboards y Configuracion

Archivos de configuracion para importar dashboards, alertas y politicas ILM
en Kibana 8.13.0 / Elasticsearch 8.13.0 del sistema Quantum File Processor.

## Estructura de Archivos

| #   | Archivo                        | Tipo   | Descripcion                                                         |
| --- | ------------------------------ | ------ | ------------------------------------------------------------------- |
| 1   | `01-data-views.ndjson`         | NDJSON | 3 Data Views: quantum-logs-\*, quantum-audit-\*, quantum-metrics-\* |
| 2   | `02-discover-logs.ndjson`      | NDJSON | Saved Search para explorar logs en Discover                         |
| 3   | `03-discover-audit.ndjson`     | NDJSON | Saved Search para explorar auditoria en Discover                    |
| 4   | `04-dashboard-logs.ndjson`     | NDJSON | Dashboard de monitoreo de logs (8 visualizaciones Lens)             |
| 5   | `05-dashboard-audit.ndjson`    | NDJSON | Dashboard de auditoria (8 visualizaciones Lens)                     |
| 6   | `06-dashboard-overview.ndjson` | NDJSON | Dashboard principal del sistema (8 visualizaciones Lens)            |
| 7   | `07-watcher-alerts.json`       | JSON   | 4 definiciones de alertas Watcher                                   |
| 8   | `08-ilm-policies.json`         | JSON   | 3 politicas de retencion ILM                                        |
| -   | `import-all.bat`               | BAT    | Script automatizado de importacion completa                         |

## Importacion Manual (Kibana UI)

### Orden de importacion

> **IMPORTANTE:** Respetar el orden de importacion. Los Data Views deben importarse primero.

```
01-data-views.ndjson       ← PRIMERO (dependencia de todos los demas)
02-discover-logs.ndjson    ← Segundo
03-discover-audit.ndjson   ← Tercero
04-dashboard-logs.ndjson   ← Cuarto
05-dashboard-audit.ndjson  ← Quinto
06-dashboard-overview.ndjson ← Sexto
```

### Pasos para importar NDJSON

1. Abrir **Kibana** → `http://localhost:5601` o la URL de OpenShift
2. Ir a **Stack Management** → **Saved Objects**
3. Click en **Import**
4. Seleccionar el archivo `.ndjson`
5. Marcar **"Automatically overwrite all saved objects"**
6. Click en **Import**
7. Repetir para cada archivo en orden

### Importar Alertas Watcher

Las alertas Watcher no se importan via NDJSON. Usar una de estas opciones:

**Opcion A: Kibana UI**

1. Ir a **Stack Management** → **Watcher** → **Create** → **Advanced watch**
2. Pegar el JSON de cada alerta desde `07-watcher-alerts.json`
3. Asignar el ID correspondiente (high-error-rate, chunk-failure-alert, dlq-alert, service-down-alert)

**Opcion B: Dev Tools**

1. Ir a **Management** → **Dev Tools**
2. Ejecutar cada PUT manualmente:

```json
PUT _watcher/watch/high-error-rate
{
  "trigger": { "schedule": { "interval": "5m" } },
  ...
}
```

### Importar Politicas ILM

**Opcion A: Kibana UI**

1. Ir a **Stack Management** → **Index Lifecycle Policies**
2. Click en **Create policy**
3. Configurar cada fase segun `08-ilm-policies.json`

**Opcion B: Dev Tools**

```json
PUT _ilm/policy/quantum-logs-policy
{
  "policy": { "phases": { ... } }
}
```

## Importacion Automatizada

Ejecutar el script BAT desde la carpeta `kibana/`:

```cmd
cd quantum-common\kibana
import-all.bat
```

Con parametros personalizados:

```cmd
import-all.bat http://localhost:5601 http://localhost:9200 elastic quantum_elastic_2026
```

Para OpenShift (via port-forward):

```cmd
REM Terminal 1: Port-forward
oc port-forward svc/quantum-kibana 5601:5601
oc port-forward svc/quantum-elasticsearch 9200:9200

REM Terminal 2: Importar
import-all.bat http://localhost:5601 http://localhost:9200 elastic quantum_elastic_2026
```

## Detalle de Dashboards

### Dashboard: Quantum Logs - Monitoreo (`04-dashboard-logs.ndjson`)

| Panel                     | Tipo             | Descripcion                        |
| ------------------------- | ---------------- | ---------------------------------- |
| Total Logs                | Metric KPI       | Cantidad total de logs             |
| Errores                   | Metric KPI       | Logs con nivel ERROR (rojo)        |
| Warnings                  | Metric KPI       | Logs con nivel WARN (amarillo)     |
| Volumen de Logs por Nivel | Area apilada     | Timeline con volumen por log.level |
| Distribucion por Nivel    | Donut            | Porcentaje por nivel de log        |
| Logs por Servicio         | Barra horizontal | Cantidad de logs por microservicio |
| Errores en el Tiempo      | Linea            | Timeline de errores por servicio   |
| Top Mensajes de Error     | Tabla            | Mensajes de error mas frecuentes   |

### Dashboard: Quantum Audit - Auditoria (`05-dashboard-audit.ndjson`)

| Panel                             | Tipo             | Descripcion                                   |
| --------------------------------- | ---------------- | --------------------------------------------- |
| Total Eventos                     | Metric KPI       | Total de eventos de auditoria                 |
| Eventos Criticos                  | Metric KPI       | Eventos con `alert.severity: critical` (rojo) |
| Pod Failures                      | Metric KPI       | Eventos tipo `pod_failure` (naranja)          |
| Eventos de Auditoria en el Tiempo | Area apilada     | Timeline por `audit.category`                 |
| Eventos por Accion                | Donut            | Distribucion por `audit.action`               |
| Eventos por Resultado             | Donut            | Distribucion por `audit.result`               |
| Eventos por Usuario               | Barra horizontal | Actividad por `audit.user`                    |
| Detalle de Eventos                | Tabla            | Tabla detallada de eventos                    |

### Dashboard: Quantum File Processor - Principal (`06-dashboard-overview.ndjson`)

| Panel                     | Tipo             | Descripcion                            |
| ------------------------- | ---------------- | -------------------------------------- |
| Total Logs                | Metric KPI       | Cantidad total de logs                 |
| Total Errores             | Metric KPI       | Total de errores (rojo)                |
| Eventos Auditoria         | Metric KPI       | Total eventos audit (verde)            |
| Chunks Procesados         | Metric KPI       | Unique count de chunk IDs (azul)       |
| Salud del Sistema         | Area             | Timeline de errores + warnings         |
| Distribucion por Servicio | Donut            | Logs por microservicio                 |
| Archivos Procesados       | Barra horizontal | Logs por `quantum.file.name`           |
| Errores Recientes         | Tabla            | Errores por servicio, mensaje y logger |

## Alertas Watcher

| Alerta                | Indice          | Condicion                     | Intervalo |
| --------------------- | --------------- | ----------------------------- | --------- |
| `high-error-rate`     | quantum-logs-\* | >10 errores en 5 min          | 5 min     |
| `chunk-failure-alert` | quantum-logs-\* | >5 chunk failures en 10 min   | 10 min    |
| `dlq-alert`           | quantum-logs-\* | Cualquier evento DLQ en 5 min | 5 min     |
| `service-down-alert`  | heartbeat-\*    | Servicio DOWN                 | 2 min     |

Todas las alertas crean documentos en el indice `quantum-alerts`.

## Politicas ILM

| Politica                 | Hot     | Warm    | Cold    | Delete   |
| ------------------------ | ------- | ------- | ------- | -------- |
| `quantum-logs-policy`    | 7 dias  | 30 dias | 90 dias | 180 dias |
| `quantum-metrics-policy` | 1 dia   | -       | -       | 30 dias  |
| `quantum-audit-policy`   | 30 dias | 90 dias | -       | 365 dias |

## Credenciales por Defecto

| Usuario         | Password             | Rol        |
| --------------- | -------------------- | ---------- |
| elastic         | quantum_elastic_2026 | superuser  |
| quantum_admin   | quantum_admin_2026   | admin      |
| quantum_dev     | quantum_dev_2026     | developer  |
| quantum_auditor | quantum_auditor_2026 | auditor    |
| quantum_ops     | quantum_ops_2026     | operations |

## Campos Principales

### Logs (quantum-logs-\*)

`@timestamp`, `log.level`, `log.logger`, `log.message`, `serviceName`,
`quantum.chunk.id`, `quantum.file.name`, `quantum.chunk.index`, `quantum.chunk.total`,
`quantum.process.id`, `quantum.correlation.id`, `trace.id`, `span.id`,
`alert.severity`, `alert.type`, `tags`

### Audit (quantum-audit-\*)

`@timestamp`, `audit.action`, `audit.category`, `audit.type`, `audit.user`,
`audit.resource`, `audit.result`, `audit.details`, `serviceName`,
`alert.severity`, `alert.type`, `tags`

### Metrics (quantum-metrics-\*)

`@timestamp`, `metric.name`, `metric.type`, `value`, `serviceName`, `tags`
