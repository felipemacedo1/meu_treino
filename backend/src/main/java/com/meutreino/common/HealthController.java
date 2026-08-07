package com.meutreino.common;

import java.time.Instant;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/health")
@Tag(name = "Health")
public class HealthController {

    @GetMapping
    public Map<String, Object> health() {
        return Map.of("status", "UP", "time", Instant.now().toString());
    }
}
