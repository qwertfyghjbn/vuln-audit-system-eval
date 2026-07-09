package com.example.demo.service;

import com.example.demo.util.TemplateUtil;

public class ReportService {

    public String renderPreview(String title) {
        return TemplateUtil.renderReportTemplate(title);
    }
}
