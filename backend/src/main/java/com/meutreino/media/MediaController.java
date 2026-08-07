package com.meutreino.media;

import java.time.Duration;

import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/media")
@Tag(name = "Midias")
public class MediaController {

    private final MediaService mediaService;

    public MediaController(MediaService mediaService) {
        this.mediaService = mediaService;
    }

    @GetMapping("/{hash}")
    public ResponseEntity<byte[]> get(@PathVariable String hash) {
        return mediaService.load(hash)
                .map(media -> ResponseEntity.ok()
                        .cacheControl(CacheControl.maxAge(Duration.ofDays(365)).cachePublic())
                        .contentType(parse(media.getContentType()))
                        .body(media.getData()))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    private MediaType parse(String contentType) {
        try {
            return contentType == null ? MediaType.APPLICATION_OCTET_STREAM : MediaType.parseMediaType(contentType);
        } catch (Exception ex) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
    }
}
