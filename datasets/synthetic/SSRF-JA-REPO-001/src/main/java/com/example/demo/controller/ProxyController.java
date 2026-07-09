package com.example.demo.controller;

import com.example.demo.service.ProxyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProxyController {

    private final ProxyService proxyService = new ProxyService();

    @GetMapping("/api/proxy/fetch")
    public ResponseEntity<String> fetch(@RequestParam String url) {
        if (url == null || url.isEmpty()) {
            return ResponseEntity.badRequest().body("url is required");
        }
        String body = proxyService.fetchRemote(url);
        if (body == null) {
            return ResponseEntity.status(502).body("fetch failed");
        }
        return ResponseEntity.ok(body);
    }
}
