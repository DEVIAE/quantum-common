package com.quantum.common.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.List;

public class Chunk {

    private final String chunkId;
    private final int chunkIndex;
    private final int totalChunks;
    private final String fileName;
    private final Instant timestamp;
    private final List<String> lines;

    @JsonCreator
    public Chunk(
            @JsonProperty("chunkId") String chunkId,
            @JsonProperty("chunkIndex") int chunkIndex,
            @JsonProperty("totalChunks") int totalChunks,
            @JsonProperty("fileName") String fileName,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("lines") List<String> lines) {
        this.chunkId = chunkId;
        this.chunkIndex = chunkIndex;
        this.totalChunks = totalChunks;
        this.fileName = fileName;
        this.timestamp = timestamp;
        this.lines = lines;
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

    public List<String> getLines() {
        return lines;
    }

    @Override
    public String toString() {
        return "Chunk{chunkId='" + chunkId + "', chunkIndex=" + chunkIndex
                + ", totalChunks=" + totalChunks + ", fileName='" + fileName
                + "', lines=" + (lines != null ? lines.size() : 0) + "}";
    }
}
