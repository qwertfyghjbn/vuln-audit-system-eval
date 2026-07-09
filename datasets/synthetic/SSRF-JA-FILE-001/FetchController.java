package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class FetchController {

    private final RestTemplate restTemplate = new RestTemplate();

    @GetMapping("/fetch")
    public String fetchUrl(@RequestParam String url) {
        if (url == null || url.isEmpty()) {
            return "No URL provided";
        }
        return restTemplate.getForObject(url, String.class);
    }
}
