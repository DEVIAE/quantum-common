package com.quantum.common.config;

public final class QueueConstants {

    private QueueConstants() {
    }

    public static final String CHUNK_QUEUE = "quantum.file.chunks";
    public static final String RESULT_QUEUE = "quantum.file.results";
    public static final String NOTIFICATION_TOPIC = "quantum.file.notifications";
    public static final String DLQ = "DLQ.quantum.file.chunks";

    public static final int DEFAULT_CHUNK_SIZE = 10_000;
    public static final int MAX_REDELIVERY_ATTEMPTS = 5;
    public static final long REDELIVERY_DELAY_MS = 5_000;
}
