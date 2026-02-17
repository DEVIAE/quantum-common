package com.quantum.common.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.quantum.common.model.ProcessingStatus;
import java.time.Instant;

public class ChunkResult {

    private final String chunkId;
    private final String fileName;
    private final ProcessingStatus status;
    private final int linesProcessed;
    private final int linesFailed;
    private final long processingTimeMs;
    private final Instant completedAt;
    private final String errorMessage;

    @JsonCreator
    public ChunkResult(
            @JsonProperty("chunkId") String chunkId,
            @JsonProperty("fileName") String fileName,
            @JsonProperty("status") ProcessingStatus status,
            @JsonProperty("linesProcessed") int linesProcessed,
            @JsonProperty("linesFailed") int linesFailed,
            @JsonProperty("processingTimeMs") long processingTimeMs,
            @JsonProperty("completedAt") Instant completedAt,
            @JsonProperty("errorMessage") String errorMessage) {
        this.chunkId = chunkId;
        this.fileName = fileName;
        this.status = status;
        this.linesProcessed = linesProcessed;
        this.linesFailed = linesFailed;
        this.processingTimeMs = processingTimeMs;
        this.completedAt = completedAt;
        this.errorMessage = errorMessage;
    }

    public static ChunkResult success(String chunkId, String fileName, int linesProcessed, long processingTimeMs) {
        return new ChunkResult(chunkId, fileName, ProcessingStatus.COMPLETED,
                linesProcessed, 0, processingTimeMs, Instant.now(), null);
    }

    public static ChunkResult partialSuccess(String chunkId, String fileName, int linesProcessed, int linesFailed,
            long processingTimeMs) {
        return new ChunkResult(chunkId, fileName, ProcessingStatus.PARTIALLY_COMPLETED,
                linesProcessed, linesFailed, processingTimeMs, Instant.now(), null);
    }

    public static ChunkResult failure(String chunkId, String fileName, String errorMessage) {
        return new ChunkResult(chunkId, fileName, ProcessingStatus.FAILED,
                0, 0, 0, Instant.now(), errorMessage);
    }

    public String getChunkId() {
        return chunkId;
    }

    public String getFileName() {
        return fileName;
    }

    public ProcessingStatus getStatus() {
        return status;
    }

    public int getLinesProcessed() {
        return linesProcessed;
    }

    public int getLinesFailed() {
        return linesFailed;
    }

    public long getProcessingTimeMs() {
        return processingTimeMs;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public String getErrorMessage() {
        return errorMessage;
    }
}
