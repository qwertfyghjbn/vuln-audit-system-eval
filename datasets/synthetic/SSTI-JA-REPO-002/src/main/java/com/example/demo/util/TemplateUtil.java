package com.example.demo.util;

import freemarker.template.Configuration;
import freemarker.template.Template;

import java.io.StringReader;
import java.io.StringWriter;
import java.util.Map;

public class TemplateUtil {

    private static final Configuration CFG;
    private static final String REPORT_TEMPLATE =
            "<h1>${title}</h1><p>Report Preview</p>";

    static {
        CFG = new Configuration(Configuration.VERSION_2_3_31);
        CFG.setDefaultEncoding("UTF-8");
    }

    public static String renderReportTemplate(String title) {
        try {
            Template template = new Template("report", new StringReader(REPORT_TEMPLATE), CFG);
            StringWriter out = new StringWriter();
            template.process(Map.of("title", title), out);
            return out.toString();
        } catch (Exception e) {
            return "";
        }
    }
}
