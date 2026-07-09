package com.example.demo.util;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileUtil {

    private static final String BASE_DIR = "/var/www/files";

    public static byte[] readFile(String filename) {
        Path filePath = Paths.get(BASE_DIR, filename);
        try {
            return Files.readAllBytes(filePath);
        } catch (IOException e) {
            return null;
        }
    }
}
