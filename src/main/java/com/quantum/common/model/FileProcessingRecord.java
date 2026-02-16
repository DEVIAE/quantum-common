package com.quantum.common.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;

public class FileProcessingRecord {

    private String fileName;
    private volatile int totalChunks;
    @JsonIgnore
    private final AtomicInteger processedChunks = new AtomicInteger(0);
    @JsonIgnore
    private final AtomicInteger failedChunks = new AtomicInteger(0);
    private volatile ProcessingStatus status;
    private Instant startTime;
    private volatile Instant endTime;

    public FileProcessingRecord() {
    }

    @JsonCreator
    public FileProcessingRecord(
            @JsonProperty("fileName") String fileName,
            @JsonProperty("totalChunks") int totalChunks) {
        this.fileName = fileName;
        this.totalChunks = totalChunks;
        this.status = ProcessingStatus.PENDING;
        this.startTime = Instant.now();
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public int getTotalChunks() {
        return totalChunks;
    }

    public void setTotalChunks(int totalChunks) {
        this.totalChunks = totalChunks;
    }

    public int getProcessedChunks() {
        return processedChunks.get();
    }

    public void setProcessedChunks(int processedChunks) {
        this.processedChunks.set(processedChunks);
    }

    public int getFailedChunks() {
        return failedChunks.get();
    }

    public void setFailedChunks(int failedChunks) {
        this.failedChunks.set(failedChunks);
    }

    public ProcessingStatus getStatus() {
        return status;
    }

    public void setStatus(ProcessingStatus status) {
        this.status = status;
    }

    public Instant getStartTime() {
        return startTime;
    }

    public void setStartTime(Instant startTime) {
        this.startTime = startTime;
    }

    public Instant getEndTime() {
        return endTime;
    }

    public void setEndTime(Instant endTime) {
        this.endTime = endTime;
    }

    public synchronized void incrementProcessed() {
        this.processedChunks.incrementAndGet();
        updateStatus();
    }

    public synchronized void incrementFailed() {
        this.failedChunks.incrementAndGet();
        updateStatus();
    }

    private void updateStatus() {
        int processed = processedChunks.get();
        int failed = failedChunks.get();
        if (processed + failed >= totalChunks) {
            this.endTime = Instant.now();
            this.status = failed > 0
                    ? ProcessingStatus.PARTIALLY_COMPLETED
                    : ProcessingStatus.COMPLETED;
        } else {
            this.status = ProcessingStatus.IN_PROGRESS;
        }
    }
}
