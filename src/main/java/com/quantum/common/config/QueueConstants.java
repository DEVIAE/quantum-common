package com.quantum.common.config;

public final class QueueConstants {

    private QueueConstants() {
    }

    // ── sftp-gateway → format-normalizer ──────────────────────────────────
    /** Evento publicado por sftp-gateway cuando un archivo es estable y listo. */
    public static final String FILE_READY_QUEUE = "file.ready";
    public static final String FILE_GATEWAY_DLQ = "DLQ.file.gateway";

    // ── format-normalizer → file-ingester ─────────────────────────────────
    /**
     * Evento publicado por format-normalizer cuando el JSONL canonico esta listo.
     */
    public static final String FILE_NORMALIZED_QUEUE = "file.normalized";
    public static final String FILE_NORMALIZER_DLQ = "DLQ.file.normalizer";

    // ── file-ingester → chunk-processor ───────────────────────────────────
    public static final String CHUNK_QUEUE = "quantum.file.chunks";
    public static final String RESULT_QUEUE = "quantum.file.results";
    public static final String NOTIFICATION_TOPIC = "quantum.file.notifications";
    public static final String DLQ = "DLQ.quantum.file.chunks";

    public static final int DEFAULT_CHUNK_SIZE = 10_000;
    public static final int MAX_REDELIVERY_ATTEMPTS = 5;
    public static final long REDELIVERY_DELAY_MS = 5_000;
}
