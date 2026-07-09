package com.example.demo.controller;

import com.example.demo.service.FileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FileController {

    private final FileService fileService = new FileService();

    @GetMapping("/api/files/download")
    public ResponseEntity<byte[]> download(@RequestParam String filename) {
        if (filename == null || filename.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        byte[] content = fileService.getFileContent(filename);
        if (content == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(content);
    }
}
