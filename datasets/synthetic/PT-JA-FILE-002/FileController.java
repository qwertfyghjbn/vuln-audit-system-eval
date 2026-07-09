package com.example.demo;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
public class FileController {

    private static final Path BASE_DIR =
            Paths.get("/var/www/files").toAbsolutePath();

    private Path resolveSafePath(String filename) throws IOException {
        Path resolved = BASE_DIR.resolve(filename).normalize();
        Path real = resolved.toRealPath();
        Path realBase = BASE_DIR.toRealPath();
        if (!real.startsWith(realBase)) {
            throw new SecurityException("path escape detected");
        }
        return real;
    }

    @GetMapping("/download")
    public byte[] downloadFile(@RequestParam String filename) throws IOException {
        if (filename == null || filename.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "filename is required");
        }

        Path safePath;
        try {
            safePath = resolveSafePath(filename);
        } catch (SecurityException e) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "access denied");
        }

        return Files.readAllBytes(safePath);
    }
}
