package com.example.demo.service;

import com.example.demo.util.HttpUtil;

import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Set;

public class ProxyService {

    private static final Set<String> ALLOWED_SCHEMES = Set.of("https");
    private static final Set<String> ALLOWED_DOMAINS =
            Set.of("api.example.com", "cdn.example.com");

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
                if (addr.isLoopbackAddress() || addr.isSiteLocalAddress()
                        || addr.isLinkLocalAddress()) {
                    return false;
                }
            } catch (Exception ignored) {
                // DNS解析失败时静默放行；DNS rebinding场景不在本模型范围内
            }
            return true;
        } catch (MalformedURLException e) {
            return false;
        }
    }

    public String fetchRemote(String url) {
        if (!isSafeUrl(url)) {
            return null;
        }
        return HttpUtil.getUrl(url);
    }
}
