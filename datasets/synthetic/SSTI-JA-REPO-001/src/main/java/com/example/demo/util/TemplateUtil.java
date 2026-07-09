package com.example.demo.util;

import freemarker.template.Configuration;
import freemarker.template.Template;

import java.io.StringReader;
import java.io.StringWriter;
import java.util.HashMap;

public class TemplateUtil {

    private static final Configuration CFG;

    static {
        CFG = new Configuration(Configuration.VERSION_2_3_31);
        CFG.setDefaultEncoding("UTF-8");
    }

    public static String renderReportTemplate(String title) {
        try {
            String templateStr = "<h1>" + title + "</h1><p>Report Preview</p>";
            Template template = new Template("report", new StringReader(templateStr), CFG);
            StringWriter out = new StringWriter();
            template.process(new HashMap<>(), out);
            return out.toString();
        } catch (Exception e) {
            return "";
        }
    }
}
