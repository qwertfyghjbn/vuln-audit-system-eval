package com.example.demo;

import freemarker.template.Configuration;
import freemarker.template.Template;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.StringReader;
import java.io.StringWriter;
import java.util.HashMap;

@RestController
public class GreetController {

    @GetMapping("/greet")
    public String greet(@RequestParam(defaultValue = "world") String name) throws Exception {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_31);
        cfg.setDefaultEncoding("UTF-8");

        String templateStr = "Hello, " + name + "!";
        Template template = new Template("greeting", new StringReader(templateStr), cfg);

        StringWriter out = new StringWriter();
        template.process(new HashMap<>(), out);
        return out.toString();
    }
}
