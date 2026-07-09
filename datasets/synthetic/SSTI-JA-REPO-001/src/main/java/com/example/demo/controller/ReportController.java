package com.example.demo.controller;

import com.example.demo.service.ReportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReportController {

    private final ReportService reportService = new ReportService();

    @GetMapping("/api/reports/preview")
    public ResponseEntity<String> preview(@RequestParam String title) {
        if (title == null || title.isEmpty()) {
            return ResponseEntity.badRequest().body("title is required");
        }
        String html = reportService.renderPreview(title);
        return ResponseEntity.ok(html);
    }
}
