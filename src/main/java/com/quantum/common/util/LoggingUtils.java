package com.quantum.common.util;

import com.quantum.common.config.ElkConstants;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.net.InetAddress;
import java.util.UUID;

/**
 * Utilidades compartidas para structured logging con ELK.
 * R3: Campos estandarizados en logs.
 * R21: Auditoria de acciones.
 * R27: Tracking de fallos.
 */
public final class LoggingUtils {

    private static final Logger auditLog = LoggerFactory.getLogger("AUDIT");

    private LoggingUtils() {
    }

    /**
     * Genera un correlation ID unico para trazar una operacion completa.
     */
    public static String generateCorrelationId() {
        return UUID.randomUUID().toString();
    }

    /**
     * Configura el MDC con informacion del servicio.
     * Debe llamarse al inicio de cada microservicio.
     */
    public static void initServiceContext(String serviceName, String serviceVersion, String environment) {
        MDC.put(ElkConstants.FIELD_SERVICE_NAME, serviceName);
        MDC.put(ElkConstants.FIELD_SERVICE_VERSION, serviceVersion);
        MDC.put(ElkConstants.FIELD_SERVICE_ENVIRONMENT, environment);
        try {
            MDC.put(ElkConstants.FIELD_HOST_NAME, InetAddress.getLocalHost().getHostName());
        } catch (Exception e) {
            MDC.put(ElkConstants.FIELD_HOST_NAME, "unknown");
        }
    }

    /**
     * Configura el MDC con informacion de un chunk siendo procesado.
     */
    public static void setChunkContext(String chunkId, String fileName, int chunkIndex, int totalChunks) {
        MDC.put(ElkConstants.MDC_CHUNK_ID, chunkId);
        MDC.put(ElkConstants.MDC_FILE_NAME, fileName);
        MDC.put(ElkConstants.MDC_CHUNK_INDEX, String.valueOf(chunkIndex));
        MDC.put(ElkConstants.MDC_TOTAL_CHUNKS, String.valueOf(totalChunks));
    }

    /**
     * Configura un correlation ID en el MDC.
     */
    public static void setCorrelationId(String correlationId) {
        MDC.put(ElkConstants.MDC_CORRELATION_ID, correlationId);
    }

    /**
     * Limpia el contexto de chunk del MDC.
     */
    public static void clearChunkContext() {
        MDC.remove(ElkConstants.MDC_CHUNK_ID);
        MDC.remove(ElkConstants.MDC_FILE_NAME);
        MDC.remove(ElkConstants.MDC_CHUNK_INDEX);
        MDC.remove(ElkConstants.MDC_TOTAL_CHUNKS);
    }

    /**
     * Limpia todo el MDC.
     */
    public static void clearAll() {
        MDC.clear();
    }

    /**
     * R21: Registra un evento de auditoria.
     */
    public static void audit(String action, String resource, String result, String details) {
        MDC.put("audit.action", action);
        MDC.put("audit.resource", resource);
        MDC.put("audit.result", result);
        auditLog.info("AUDIT: action={}, resource={}, result={}, details={}",
                action, resource, result, details);
        MDC.remove("audit.action");
        MDC.remove("audit.resource");
        MDC.remove("audit.result");
    }

    /**
     * R27: Registra informacion de fallo con contexto completo.
     */
    public static void logFailure(Logger logger, String service, String component,
            String operation, Throwable error) {
        MDC.put("failure.service", service);
        MDC.put("failure.component", component);
        MDC.put("failure.operation", operation);
        MDC.put("failure.timestamp", java.time.Instant.now().toString());

        logger.error("FAILURE: service={}, component={}, operation={}, error={}",
                service, component, operation, error.getMessage(), error);

        MDC.remove("failure.service");
        MDC.remove("failure.component");
        MDC.remove("failure.operation");
        MDC.remove("failure.timestamp");
    }
}
