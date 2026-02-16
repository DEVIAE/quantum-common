package com.quantum.common.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

public class FileProcessingRecord {

    private String fileName;
    private int totalChunks;
    private int processedChunks;
    private int failedChunks;
    private ProcessingStatus status;
    private Instant startTime;
    private Instant endTime;

    public FileProcessingRecord() {
    }

    @JsonCreator
    public FileProcessingRecord(
            @JsonProperty("fileName") String fileName,
            @JsonProperty("totalChunks") int totalChunks) {
        this.fileName = fileName;
        this.totalChunks = totalChunks;
        this.processedChunks = 0;
        this.failedChunks = 0;
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
        return processedChunks;
    }

    public void setProcessedChunks(int processedChunks) {
        this.processedChunks = processedChunks;
    }

    public int getFailedChunks() {
        return failedChunks;
    }

    public void setFailedChunks(int failedChunks) {
        this.failedChunks = failedChunks;
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

    public void incrementProcessed() {
        this.processedChunks++;
        updateStatus();
    }

    public void incrementFailed() {
        this.failedChunks++;
        updateStatus();
    }

    private void updateStatus() {
        if (processedChunks + failedChunks >= totalChunks) {
            this.endTime = Instant.now();
            this.status = failedChunks > 0
                    ? ProcessingStatus.PARTIALLY_COMPLETED
                    : ProcessingStatus.COMPLETED;
        } else {
            this.status = ProcessingStatus.IN_PROGRESS;
        }
    }
}
