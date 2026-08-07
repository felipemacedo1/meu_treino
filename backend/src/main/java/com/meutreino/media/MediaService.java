package com.meutreino.media;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Proxy + cache local das midias do wger.
 *
 * <p>O app nunca aponta para o wger diretamente: as URLs sao trocadas por
 * "/api/media/{hash}". Na primeira requisicao o backend baixa o arquivo e guarda
 * os bytes no Postgres; depois disso funciona sem internet.
 *
 * <p>Somente URLs que existem no catalogo local sao aceitas (evita SSRF).
 */
@Service
public class MediaService {

    private static final Logger log = LoggerFactory.getLogger(MediaService.class);
    private static final int MAX_BYTES = 20 * 1024 * 1024;

    private final MediaCacheRepository repository;
    private final JdbcTemplate jdbcTemplate;
    private final ConcurrentMap<String, String> hashToUrl = new ConcurrentHashMap<>();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    public MediaService(MediaCacheRepository repository, JdbcTemplate jdbcTemplate) {
        this.repository = repository;
        this.jdbcTemplate = jdbcTemplate;
    }

    /** Recarrega o mapa hash -> url a partir do catalogo. */
    public synchronized void reloadRegistry() {
        List<String> urls = jdbcTemplate.queryForList(
                "SELECT url FROM exercise_images UNION SELECT url FROM exercise_videos", String.class);
        hashToUrl.clear();
        for (String url : urls) {
            hashToUrl.put(hash(url), url);
        }
        log.info("Registro de midias carregado: {} arquivos", hashToUrl.size());
    }

    public void register(String url) {
        if (url != null && !url.isBlank()) {
            hashToUrl.put(hash(url), url);
        }
    }

    /** Converte a URL original na URL servida pela nossa API. */
    public String publicUrl(String originalUrl) {
        if (originalUrl == null || originalUrl.isBlank()) {
            return null;
        }
        String h = hash(originalUrl);
        hashToUrl.putIfAbsent(h, originalUrl);
        return "/api/media/" + h;
    }

    public Optional<String> resolve(String hash) {
        return Optional.ofNullable(hashToUrl.get(hash));
    }

    @Transactional
    public Optional<MediaCache> load(String hash) {
        Optional<MediaCache> cached = repository.findByUrlHash(hash);
        if (cached.isPresent()) {
            return cached;
        }
        String url = hashToUrl.get(hash);
        if (url == null) {
            return Optional.empty();
        }
        return download(hash, url);
    }

    private Optional<MediaCache> download(String hash, String url) {
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(60))
                    .header("User-Agent", "meu-treino/1.0")
                    .GET()
                    .build();
            HttpResponse<InputStream> response = httpClient.send(request, HttpResponse.BodyHandlers.ofInputStream());
            if (response.statusCode() != 200) {
                log.warn("Midia {} retornou HTTP {}", url, response.statusCode());
                return Optional.empty();
            }
            byte[] bytes;
            try (InputStream in = response.body()) {
                bytes = in.readNBytes(MAX_BYTES);
            }
            if (bytes.length == 0) {
                return Optional.empty();
            }
            MediaCache entity = new MediaCache();
            entity.setUrlHash(hash);
            entity.setUrl(url);
            entity.setContentType(response.headers().firstValue("content-type").orElse(guessContentType(url)));
            entity.setSizeBytes(bytes.length);
            entity.setData(bytes);
            return Optional.of(repository.save(entity));
        } catch (Exception ex) {
            log.warn("Falha ao baixar midia {}: {}", url, ex.getMessage());
            return Optional.empty();
        }
    }

    private String guessContentType(String url) {
        String lower = url.toLowerCase();
        if (lower.endsWith(".png")) {
            return "image/png";
        }
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return "image/jpeg";
        }
        if (lower.endsWith(".gif")) {
            return "image/gif";
        }
        if (lower.endsWith(".svg")) {
            return "image/svg+xml";
        }
        if (lower.endsWith(".webm")) {
            return "video/webm";
        }
        if (lower.endsWith(".mp4")) {
            return "video/mp4";
        }
        return "application/octet-stream";
    }

    private static String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] out = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(out).substring(0, 32);
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }
}
