package com.example.demo.util;

import org.springframework.web.client.RestTemplate;

public class HttpUtil {

    private static final RestTemplate REST_TEMPLATE = new RestTemplate();

    public static String getUrl(String url) {
        try {
            return REST_TEMPLATE.getForObject(url, String.class);
        } catch (Exception e) {
            return null;
        }
    }
}
