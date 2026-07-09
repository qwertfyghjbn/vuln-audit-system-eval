package com.example.demo;

import freemarker.template.Configuration;
import freemarker.template.Template;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.StringReader;
import java.io.StringWriter;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

@RestController
public class GreetController {

    private static final String GREETING_TEMPLATE = "Hello, ${name}!";
    private static final Pattern ALLOWED_NAME = Pattern.compile("^[A-Za-z0-9 _-]{1,64}$");

    private String sanitizeName(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String stripped = raw.strip();
        return ALLOWED_NAME.matcher(stripped).matches() ? stripped : null;
    }

    @GetMapping("/greet")
    public ResponseEntity<String> greet(@RequestParam String name) throws Exception {
        String safeName = sanitizeName(name);
        if (safeName == null) {
            return ResponseEntity.badRequest().body("Invalid name");
        }

        Configuration cfg = new Configuration(Configuration.VERSION_2_3_31);
        cfg.setDefaultEncoding("UTF-8");

        Template template = new Template("greeting", new StringReader(GREETING_TEMPLATE), cfg);
        Map<String, Object> model = new HashMap<>();
        model.put("name", safeName);

        StringWriter out = new StringWriter();
        template.process(model, out);
        return ResponseEntity.ok(out.toString());
    }
}
