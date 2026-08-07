package com.meutreino.config;

import java.time.Duration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Bean
    public RestClient wgerRestClient(AppProperties properties) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(15));
        factory.setReadTimeout(Duration.ofSeconds(properties.wger().timeoutSeconds()));
        return RestClient.builder()
                .baseUrl(properties.wger().baseUrl())
                .requestFactory(factory)
                .defaultHeader("Accept", "application/json")
                .defaultHeader("User-Agent", "meu-treino/1.0")
                .build();
    }
}
