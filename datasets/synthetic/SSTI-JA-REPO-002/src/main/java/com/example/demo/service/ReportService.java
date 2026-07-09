package com.example.demo.service;

import com.example.demo.util.TemplateUtil;

import java.util.regex.Pattern;

public class ReportService {

    private static final Pattern ALLOWED_TITLE =
            Pattern.compile("^[A-Za-z0-9 _,.:;!?()-]{1,128}$");

    private String validateTitle(String title) {
        if (title == null) return null;
        String stripped = title.strip();
        return ALLOWED_TITLE.matcher(stripped).matches() ? stripped : null;
    }

    public String renderPreview(String title) {
        String safeTitle = validateTitle(title);
        if (safeTitle == null) {
            return null;
        }
        return TemplateUtil.renderReportTemplate(safeTitle);
    }
}
