package com.example.demo;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Set;

@RestController
public class FetchController {

    private static final Set<String> ALLOWED_SCHEMES = Set.of("https");
    private static final Set<String> ALLOWED_DOMAINS = Set.of("api.example.com", "cdn.example.com");

    private boolean isSafeUrl(String rawUrl) {
        try {
            URL parsed = new URL(rawUrl);
            if (!ALLOWED_SCHEMES.contains(parsed.getProtocol())) {
                return false;
            }
            String host = parsed.getHost();
            if (host == null || !ALLOWED_DOMAINS.contains(host)) {
                return false;
            }
            try {
                InetAddress addr = InetAddress.getByName(host);
                if (addr.isLoopbackAddress() || addr.isSiteLocalAddress() || addr.isLinkLocalAddress()) {
                    return false;
                }
            } catch (Exception ignored) {
                // not a raw IP; domain allowlist already enforces the host
            }
            return true;
        } catch (MalformedURLException e) {
            return false;
        }
    }

    private RestTemplate buildNoRedirectTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory() {
            @Override
            protected void prepareConnection(HttpURLConnection conn, String method)
                    throws java.io.IOException {
                super.prepareConnection(conn, method);
                conn.setInstanceFollowRedirects(false);
            }
        };
        return new RestTemplate(factory);
    }

    @GetMapping("/fetch")
    public ResponseEntity<String> fetchUrl(@RequestParam String url) {
        if (url == null || url.isEmpty()) {
            return ResponseEntity.badRequest().body("No URL provided");
        }
        if (!isSafeUrl(url)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("URL not allowed");
        }
        String body = buildNoRedirectTemplate().getForObject(url, String.class);
        return ResponseEntity.ok(body);
    }
}
