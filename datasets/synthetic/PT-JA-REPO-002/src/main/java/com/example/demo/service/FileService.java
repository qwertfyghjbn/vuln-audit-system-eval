package com.example.demo.service;

import com.example.demo.util.FileUtil;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileService {

    private static final Path BASE_DIR =
            Paths.get("/var/www/files").toAbsolutePath();

    private Path resolveSafePath(String filename) throws IOException {
        Path resolved = BASE_DIR.resolve(filename).normalize();
        if (resolved.isAbsolute() && !resolved.startsWith(BASE_DIR)) {
            throw new SecurityException("path escape detected");
        }
        Path real = resolved.toRealPath();
        Path realBase = BASE_DIR.toRealPath();
        if (!real.startsWith(realBase)) {
            throw new SecurityException("path escape detected after symlink resolution");
        }
        return real;
    }

    public byte[] getFileContent(String filename) {
        Path safePath;
        try {
            safePath = resolveSafePath(filename);
        } catch (SecurityException | IOException e) {
            return null;
        }
        return FileUtil.readFile(safePath);
    }
}
