package com.example.demo.service;

import com.example.demo.util.HttpUtil;

public class ProxyService {

    public String fetchRemote(String url) {
        return HttpUtil.getUrl(url);
    }
}
