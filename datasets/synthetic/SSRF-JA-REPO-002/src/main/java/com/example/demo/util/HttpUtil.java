package com.example.demo.util;

import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

import java.net.HttpURLConnection;

public class HttpUtil {

    private static final RestTemplate REST_TEMPLATE;

    static {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory() {
            @Override
            protected void prepareConnection(HttpURLConnection conn, String method)
                    throws java.io.IOException {
                super.prepareConnection(conn, method);
                conn.setInstanceFollowRedirects(false);
            }
        };
        REST_TEMPLATE = new RestTemplate(factory);
    }

    public static String getUrl(String url) {
        try {
            return REST_TEMPLATE.getForObject(url, String.class);
        } catch (Exception e) {
            return null;
        }
    }
}
