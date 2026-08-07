package com.meutreino.media;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "media_cache")
@Getter
@Setter
public class MediaCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "url_hash", nullable = false, unique = true)
    private String urlHash;

    @Column(nullable = false, columnDefinition = "text")
    private String url;

    @Column(name = "content_type")
    private String contentType;

    @Column(name = "size_bytes", nullable = false)
    private int sizeBytes;

    @Column(name = "data", nullable = false, columnDefinition = "bytea")
    private byte[] data;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
