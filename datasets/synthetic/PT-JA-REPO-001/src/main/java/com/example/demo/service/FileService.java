package com.example.demo.service;

import com.example.demo.util.FileUtil;

public class FileService {

    public byte[] getFileContent(String filename) {
        return FileUtil.readFile(filename);
    }
}
