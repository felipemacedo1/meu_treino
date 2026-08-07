package com.meutreino.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Todas as configuracoes customizadas da aplicacao, agrupadas sob o prefixo "app".
 */
@ConfigurationProperties(prefix = "app")
public record AppProperties(Jwt jwt, Cors cors, Wger wger) {

    public record Jwt(String secret, long expirationDays) {
    }

    public record Cors(String allowedOrigins) {
    }

    public record Wger(
            String baseUrl,
            int language,
            int pageSize,
            int maxExercises,
            boolean syncOnStartup,
            int timeoutSeconds
    ) {
    }
}
