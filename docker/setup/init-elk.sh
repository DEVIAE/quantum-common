#!/bin/bash
# =============================================================================
# Quantum ELK - Initialization Script
# Configura: Seguridad, RBAC, ILM, Index Templates, Alertas, Backup
# Requisitos: R3, R4, R5, R8, R12, R14, R23
# =============================================================================

set -e

ELASTIC_URL="http://elasticsearch:9200"
ELASTIC_USER="elastic"
ELASTIC_PASS="${ELASTIC_PASSWORD:-quantum_elastic_2026}"
KIBANA_PASS="${KIBANA_PASSWORD:-quantum_kibana_2026}"

echo "============================================="
echo "  Quantum ELK - Initialization"
echo "============================================="

# Wait for Elasticsearch to be ready
echo "[1/9] Waiting for Elasticsearch..."
until curl -sf -u "${ELASTIC_USER}:${ELASTIC_PASS}" "${ELASTIC_URL}/_cluster/health?wait_for_status=yellow&timeout=30s" > /dev/null 2>&1; do
  echo "  Elasticsearch not ready, waiting 5s..."
  sleep 5
done
echo "  Elasticsearch is ready!"

# =============================================================================
# R5/R14/R23: Security & RBAC Setup
# =============================================================================
echo "[2/9] Setting up security and RBAC..."

# Set kibana_system password
curl -sf -X POST -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/user/kibana_system/_password" \
  -d "{\"password\":\"${KIBANA_PASS}\"}" || true

# R23: Create roles
# Rol: quantum_admin - Acceso total a indices quantum
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/role/quantum_admin" \
  -d '{
    "cluster": ["monitor", "manage_index_templates", "manage_ilm", "manage_pipeline"],
    "indices": [
      {
        "names": ["quantum-*"],
        "privileges": ["all"]
      }
    ],
    "applications": [
      {
        "application": "kibana-.kibana",
        "privileges": ["all"],
        "resources": ["*"]
      }
    ]
  }'
echo ""

# Rol: quantum_developer - Lectura de logs + dashboards
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/role/quantum_developer" \
  -d '{
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["quantum-logs-*", "quantum-metrics-*"],
        "privileges": ["read", "view_index_metadata"]
      }
    ],
    "applications": [
      {
        "application": "kibana-.kibana",
        "privileges": ["read"],
        "resources": ["*"]
      }
    ]
  }'
echo ""

# Rol: quantum_auditor - Solo lectura de audit logs
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/role/quantum_auditor" \
  -d '{
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["quantum-audit-*"],
        "privileges": ["read", "view_index_metadata"]
      }
    ],
    "applications": [
      {
        "application": "kibana-.kibana",
        "privileges": ["read"],
        "resources": ["*"]
      }
    ]
  }'
echo ""

# Rol: quantum_ops - Operaciones (monitoreo, metricas, salud)
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/role/quantum_ops" \
  -d '{
    "cluster": ["monitor", "manage_ilm", "manage_index_templates"],
    "indices": [
      {
        "names": ["quantum-*", "heartbeat-*", "metricbeat-*"],
        "privileges": ["read", "view_index_metadata", "manage"]
      }
    ],
    "applications": [
      {
        "application": "kibana-.kibana",
        "privileges": ["all"],
        "resources": ["*"]
      }
    ]
  }'
echo ""

# Create users
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/user/quantum_admin" \
  -d '{"password":"quantum_admin_2026","roles":["quantum_admin"],"full_name":"Quantum Admin"}'
echo ""

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/user/quantum_dev" \
  -d '{"password":"quantum_dev_2026","roles":["quantum_developer"],"full_name":"Quantum Developer"}'
echo ""

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/user/quantum_auditor" \
  -d '{"password":"quantum_auditor_2026","roles":["quantum_auditor"],"full_name":"Quantum Auditor"}'
echo ""

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_security/user/quantum_ops" \
  -d '{"password":"quantum_ops_2026","roles":["quantum_ops"],"full_name":"Quantum Operations"}'
echo ""

echo "  RBAC setup complete!"

# =============================================================================
# R12: ILM Policies - Politicas de retencion de datos
# =============================================================================
echo "[3/9] Creating ILM policies..."

# Logs: hot 7 dias -> warm 30 dias -> cold 90 dias -> delete 180 dias
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_ilm/policy/quantum-logs-policy" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_primary_shard_size": "10gb",
              "max_age": "7d"
            },
            "set_priority": { "priority": 100 }
          }
        },
        "warm": {
          "min_age": "30d",
          "actions": {
            "shrink": { "number_of_shards": 1 },
            "forcemerge": { "max_num_segments": 1 },
            "set_priority": { "priority": 50 }
          }
        },
        "cold": {
          "min_age": "90d",
          "actions": {
            "set_priority": { "priority": 0 }
          }
        },
        "delete": {
          "min_age": "180d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
echo ""

# Metrics: retener 30 dias
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_ilm/policy/quantum-metrics-policy" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_primary_shard_size": "5gb",
              "max_age": "1d"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": { "delete": {} }
        }
      }
    }
  }'
echo ""

# Audit: retener 365 dias (cumplimiento normativo)
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_ilm/policy/quantum-audit-policy" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_primary_shard_size": "10gb",
              "max_age": "30d"
            }
          }
        },
        "warm": {
          "min_age": "90d",
          "actions": {
            "forcemerge": { "max_num_segments": 1 }
          }
        },
        "delete": {
          "min_age": "365d",
          "actions": { "delete": {} }
        }
      }
    }
  }'
echo ""

echo "  ILM policies created!"

# =============================================================================
# R3: Index Templates - Campos indexados
# =============================================================================
echo "[4/9] Creating index templates..."

# Template para logs
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_index_template/quantum-logs-template" \
  -d '{
    "index_patterns": ["quantum-logs-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.lifecycle.name": "quantum-logs-policy",
        "index.lifecycle.rollover_alias": "quantum-logs"
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "log.level": { "type": "keyword" },
          "log.logger": { "type": "keyword" },
          "log.message": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 512 } } },
          "process.thread.name": { "type": "keyword" },
          "error.stack_trace": { "type": "text" },
          "serviceName": { "type": "keyword" },
          "serviceVersion": { "type": "keyword" },
          "serviceEnvironment": { "type": "keyword" },
          "hostName": { "type": "keyword" },
          "quantum.chunk.id": { "type": "keyword" },
          "quantum.file.name": { "type": "keyword" },
          "quantum.chunk.index": { "type": "integer" },
          "quantum.chunk.total": { "type": "integer" },
          "quantum.process.id": { "type": "keyword" },
          "quantum.correlation.id": { "type": "keyword" },
          "trace.id": { "type": "keyword" },
          "span.id": { "type": "keyword" },
          "alert.severity": { "type": "keyword" },
          "alert.type": { "type": "keyword" },
          "tags": { "type": "keyword" }
        }
      }
    },
    "priority": 200
  }'
echo ""

# Template para metricas
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_index_template/quantum-metrics-template" \
  -d '{
    "index_patterns": ["quantum-metrics-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.lifecycle.name": "quantum-metrics-policy",
        "index.lifecycle.rollover_alias": "quantum-metrics"
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "metric.name": { "type": "keyword" },
          "metric.type": { "type": "keyword" },
          "value": { "type": "double" },
          "serviceName": { "type": "keyword" },
          "tags": { "type": "keyword" }
        }
      }
    },
    "priority": 200
  }'
echo ""

# Template para auditoria
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_index_template/quantum-audit-template" \
  -d '{
    "index_patterns": ["quantum-audit-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.lifecycle.name": "quantum-audit-policy",
        "index.lifecycle.rollover_alias": "quantum-audit"
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "audit.action": { "type": "keyword" },
          "audit.category": { "type": "keyword" },
          "audit.type": { "type": "keyword" },
          "audit.user": { "type": "keyword" },
          "audit.resource": { "type": "keyword" },
          "audit.result": { "type": "keyword" },
          "audit.details": { "type": "text" },
          "serviceName": { "type": "keyword" },
          "alert.severity": { "type": "keyword" },
          "alert.type": { "type": "keyword" },
          "tags": { "type": "keyword" }
        }
      }
    },
    "priority": 200
  }'
echo ""

echo "  Index templates created!"

# =============================================================================
# R8: Backup Repository
# =============================================================================
echo "[5/9] Setting up backup repository..."

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_snapshot/quantum-backup" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/usr/share/elasticsearch/backup",
      "compress": true
    }
  }'
echo ""

echo "  Backup repository created!"

# =============================================================================
# R8: Create initial snapshot policy (SLM)
# =============================================================================
echo "[6/9] Creating snapshot lifecycle policy..."

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_slm/policy/quantum-daily-backup" \
  -d '{
    "schedule": "0 30 1 * * ?",
    "name": "<quantum-snapshot-{now/d}>",
    "repository": "quantum-backup",
    "config": {
      "indices": ["quantum-*"],
      "ignore_unavailable": true,
      "include_global_state": false
    },
    "retention": {
      "expire_after": "30d",
      "min_count": 5,
      "max_count": 50
    }
  }'
echo ""

echo "  Snapshot policy created!"

# =============================================================================
# R4: Alerting - Watcher rules
# =============================================================================
echo "[7/9] Creating alerting rules..."

# Alerta: Tasa alta de errores (>10 errores en 5 minutos)
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_watcher/watch/high-error-rate" \
  -d '{
    "trigger": {
      "schedule": { "interval": "5m" }
    },
    "input": {
      "search": {
        "request": {
          "indices": ["quantum-logs-*"],
          "body": {
            "size": 0,
            "query": {
              "bool": {
                "must": [
                  { "term": { "log.level": "ERROR" } },
                  { "range": { "@timestamp": { "gte": "now-5m" } } }
                ]
              }
            }
          }
        }
      }
    },
    "condition": {
      "compare": { "ctx.payload.hits.total.value": { "gt": 10 } }
    },
    "actions": {
      "log_alert": {
        "logging": {
          "text": "ALERT: High error rate detected - {{ctx.payload.hits.total.value}} errors in last 5 minutes"
        }
      },
      "index_alert": {
        "index": {
          "index": "quantum-alerts",
          "doc_id": "high-error-rate-{{ctx.trigger.triggered_time}}"
        }
      }
    }
  }'
echo ""

# Alerta: Chunks fallidos (>5 en 10 minutos)
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_watcher/watch/chunk-failure-alert" \
  -d '{
    "trigger": {
      "schedule": { "interval": "10m" }
    },
    "input": {
      "search": {
        "request": {
          "indices": ["quantum-logs-*"],
          "body": {
            "size": 0,
            "query": {
              "bool": {
                "must": [
                  { "terms": { "tags": ["chunk_failure"] } },
                  { "range": { "@timestamp": { "gte": "now-10m" } } }
                ]
              }
            }
          }
        }
      }
    },
    "condition": {
      "compare": { "ctx.payload.hits.total.value": { "gt": 5 } }
    },
    "actions": {
      "log_alert": {
        "logging": {
          "text": "ALERT: Multiple chunk failures detected - {{ctx.payload.hits.total.value}} failures in last 10 minutes"
        }
      },
      "index_alert": {
        "index": {
          "index": "quantum-alerts",
          "doc_id": "chunk-failure-{{ctx.trigger.triggered_time}}"
        }
      }
    }
  }'
echo ""

# Alerta: DLQ events
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_watcher/watch/dlq-alert" \
  -d '{
    "trigger": {
      "schedule": { "interval": "5m" }
    },
    "input": {
      "search": {
        "request": {
          "indices": ["quantum-logs-*"],
          "body": {
            "size": 0,
            "query": {
              "bool": {
                "must": [
                  { "terms": { "tags": ["dlq_event"] } },
                  { "range": { "@timestamp": { "gte": "now-5m" } } }
                ]
              }
            }
          }
        }
      }
    },
    "condition": {
      "compare": { "ctx.payload.hits.total.value": { "gt": 0 } }
    },
    "actions": {
      "log_alert": {
        "logging": {
          "text": "ALERT: Messages sent to DLQ - {{ctx.payload.hits.total.value}} DLQ events in last 5 minutes"
        }
      },
      "index_alert": {
        "index": {
          "index": "quantum-alerts",
          "doc_id": "dlq-event-{{ctx.trigger.triggered_time}}"
        }
      }
    }
  }'
echo ""

# R27: Alerta de servicio caido
curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_watcher/watch/service-down-alert" \
  -d '{
    "trigger": {
      "schedule": { "interval": "2m" }
    },
    "input": {
      "search": {
        "request": {
          "indices": ["heartbeat-*"],
          "body": {
            "size": 0,
            "query": {
              "bool": {
                "must": [
                  { "term": { "monitor.status": "down" } },
                  { "range": { "@timestamp": { "gte": "now-2m" } } }
                ]
              }
            }
          }
        }
      }
    },
    "condition": {
      "compare": { "ctx.payload.hits.total.value": { "gt": 0 } }
    },
    "actions": {
      "log_alert": {
        "logging": {
          "text": "CRITICAL: Service DOWN detected - {{ctx.payload.hits.total.value}} health check failures"
        }
      },
      "index_alert": {
        "index": {
          "index": "quantum-alerts",
          "doc_id": "service-down-{{ctx.trigger.triggered_time}}"
        }
      }
    }
  }'
echo ""

echo "  Alerting rules created!"

# =============================================================================
# R18: Indice de alertas/notificaciones
# =============================================================================
echo "[8/9] Creating alerts index template..."

curl -sf -X PUT -u "${ELASTIC_USER}:${ELASTIC_PASS}" \
  -H "Content-Type: application/json" \
  "${ELASTIC_URL}/_index_template/quantum-alerts-template" \
  -d '{
    "index_patterns": ["quantum-alerts*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "alert.type": { "type": "keyword" },
          "alert.severity": { "type": "keyword" },
          "alert.description": { "type": "text" },
          "alert.resolved": { "type": "boolean" }
        }
      }
    },
    "priority": 200
  }'
echo ""

echo "  Alerts index template created!"

# =============================================================================
# Summary
# =============================================================================
echo "[9/9] Initialization complete!"
echo "============================================="
echo "  Quantum ELK Stack Initialized Successfully"
echo "============================================="
echo ""
echo "  Elasticsearch: http://localhost:9200"
echo "  Kibana:        http://localhost:5601"
echo "  Logstash TCP:  localhost:5000"
echo ""
echo "  Users created:"
echo "    elastic       / ${ELASTIC_PASS} (superuser)"
echo "    quantum_admin / quantum_admin_2026 (admin)"
echo "    quantum_dev   / quantum_dev_2026 (developer)"
echo "    quantum_auditor / quantum_auditor_2026 (auditor)"
echo "    quantum_ops   / quantum_ops_2026 (operations)"
echo ""
echo "  ILM Policies:"
echo "    quantum-logs-policy    : 7d hot -> 30d warm -> 90d cold -> 180d delete"
echo "    quantum-metrics-policy : 1d hot -> 30d delete"
echo "    quantum-audit-policy   : 30d hot -> 90d warm -> 365d delete"
echo ""
echo "  Alerts:"
echo "    high-error-rate   : >10 errors in 5 min"
echo "    chunk-failure     : >5 chunk failures in 10 min"
echo "    dlq-alert         : Any DLQ event"
echo "    service-down      : Service health check failure"
echo "============================================="
