package com.quantum.common.util;

import java.util.UUID;

public final class ChunkIdGenerator {

    private ChunkIdGenerator() {
    }

    public static String generate(String fileName, int chunkIndex) {
        return fileName + "-chunk-" + chunkIndex + "-" + UUID.randomUUID().toString().substring(0, 8);
    }
}
