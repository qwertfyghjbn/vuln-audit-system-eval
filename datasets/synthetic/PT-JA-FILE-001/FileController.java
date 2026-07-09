package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
public class FileController {

    private static final String BASE_DIR = "/var/www/files";

    @GetMapping("/download")
    public byte[] downloadFile(@RequestParam String filename) throws IOException {
        if (filename == null || filename.isEmpty()) {
            throw new IllegalArgumentException("filename is required");
        }

        Path filePath = Paths.get(BASE_DIR, filename);
        return Files.readAllBytes(filePath);
    }
}
