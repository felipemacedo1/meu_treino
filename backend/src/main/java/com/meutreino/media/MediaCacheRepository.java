package com.meutreino.media;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MediaCacheRepository extends JpaRepository<MediaCache, Long> {

    Optional<MediaCache> findByUrlHash(String urlHash);
}
