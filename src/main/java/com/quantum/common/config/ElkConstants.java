package com.quantum.common.config;

/**
 * Constantes de configuracion ELK compartidas entre microservicios.
 * R1: Pipeline de ingesta - puertos y hosts estandarizados.
 * R3: Campos indexados - nombres de campos estandarizados.
 * R11: Versionado del pipeline.
 */
public final class ElkConstants {

    private ElkConstants() {
    }

    // =========================================================================
    // Logstash connection
    // =========================================================================
    public static final String LOGSTASH_HOST = "localhost";
    public static final int LOGSTASH_TCP_PORT = 5000;
    public static final int LOGSTASH_AUDIT_PORT = 5001;

    // =========================================================================
    // R3: Campos estandarizados para indexacion
    // =========================================================================
    public static final String FIELD_SERVICE_NAME = "serviceName";
    public static final String FIELD_SERVICE_VERSION = "serviceVersion";
    public static final String FIELD_SERVICE_ENVIRONMENT = "serviceEnvironment";
    public static final String FIELD_HOST_NAME = "hostName";

    // Campos de negocio (MDC)
    public static final String MDC_CHUNK_ID = "chunkId";
    public static final String MDC_FILE_NAME = "fileName";
    public static final String MDC_CHUNK_INDEX = "chunkIndex";
    public static final String MDC_TOTAL_CHUNKS = "totalChunks";
    public static final String MDC_PROCESS_ID = "processInstanceId";
    public static final String MDC_CORRELATION_ID = "correlationId";
    public static final String MDC_TRACE_ID = "traceId";
    public static final String MDC_SPAN_ID = "spanId";

    // =========================================================================
    // R12: Indices de Elasticsearch
    // =========================================================================
    public static final String INDEX_LOGS_PREFIX = "quantum-logs";
    public static final String INDEX_METRICS_PREFIX = "quantum-metrics";
    public static final String INDEX_AUDIT_PREFIX = "quantum-audit";
    public static final String INDEX_ALERTS = "quantum-alerts";

    // =========================================================================
    // R11: Version del pipeline
    // =========================================================================
    public static final String PIPELINE_VERSION = "1.0.0";

    // =========================================================================
    // R21: Tipos de eventos de auditoria
    // =========================================================================
    public static final String AUDIT_TYPE_FILE_INGESTED = "file_ingested";
    public static final String AUDIT_TYPE_CHUNK_PROCESSED = "chunk_processed";
    public static final String AUDIT_TYPE_CHUNK_FAILED = "chunk_failed";
    public static final String AUDIT_TYPE_DLQ_EVENT = "dlq_event";
    public static final String AUDIT_TYPE_SERVICE_START = "service_start";
    public static final String AUDIT_TYPE_SERVICE_STOP = "service_stop";
    public static final String AUDIT_TYPE_CONFIG_CHANGE = "config_change";
    public static final String AUDIT_TYPE_POD_FAILURE = "pod_failure";
}
