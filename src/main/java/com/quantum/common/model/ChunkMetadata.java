package com.quantum.common.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

public class ChunkMetadata {

    private final String chunkId;
    private final int chunkIndex;
    private final int totalChunks;
    private final String fileName;
    private final Instant timestamp;
    private final int lineCount;

    @JsonCreator
    public ChunkMetadata(
            @JsonProperty("chunkId") String chunkId,
            @JsonProperty("chunkIndex") int chunkIndex,
            @JsonProperty("totalChunks") int totalChunks,
            @JsonProperty("fileName") String fileName,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("lineCount") int lineCount) {
        this.chunkId = chunkId;
        this.chunkIndex = chunkIndex;
        this.totalChunks = totalChunks;
        this.fileName = fileName;
        this.timestamp = timestamp;
        this.lineCount = lineCount;
    }

    public String getChunkId() {
        return chunkId;
    }

    public int getChunkIndex() {
        return chunkIndex;
    }

    public int getTotalChunks() {
        return totalChunks;
    }

    public String getFileName() {
        return fileName;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public int getLineCount() {
        return lineCount;
    }
}
