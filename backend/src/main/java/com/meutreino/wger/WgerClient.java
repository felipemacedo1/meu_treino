package com.meutreino.wger;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import com.meutreino.config.AppProperties;
import com.meutreino.wger.WgerDtos.Page;
import com.meutreino.wger.WgerDtos.WgerCategory;
import com.meutreino.wger.WgerDtos.WgerEquipment;
import com.meutreino.wger.WgerDtos.WgerExercise;
import com.meutreino.wger.WgerDtos.WgerMuscle;

@Component
public class WgerClient {

    private static final Logger log = LoggerFactory.getLogger(WgerClient.class);

    private final RestClient client;
    private final AppProperties properties;

    public WgerClient(RestClient wgerRestClient, AppProperties properties) {
        this.client = wgerRestClient;
        this.properties = properties;
    }

    public List<WgerMuscle> muscles() {
        return page("/muscle/?format=json&limit=100", new ParameterizedTypeReference<Page<WgerMuscle>>() {
        }).results();
    }

    public List<WgerEquipment> equipment() {
        return page("/equipment/?format=json&limit=100", new ParameterizedTypeReference<Page<WgerEquipment>>() {
        }).results();
    }

    public List<WgerCategory> categories() {
        return page("/exercisecategory/?format=json&limit=100", new ParameterizedTypeReference<Page<WgerCategory>>() {
        }).results();
    }

    /**
     * Baixa o catalogo completo de exercicios paginando a API do wger.
     */
    public List<WgerExercise> exercises() {
        List<WgerExercise> all = new ArrayList<>();
        int pageSize = properties.wger().pageSize();
        int max = properties.wger().maxExercises();
        int offset = 0;
        while (true) {
            String uri = "/exerciseinfo/?format=json&limit=" + pageSize + "&offset=" + offset;
            Page<WgerExercise> page = page(uri, new ParameterizedTypeReference<Page<WgerExercise>>() {
            });
            if (page.results() == null || page.results().isEmpty()) {
                break;
            }
            all.addAll(page.results());
            log.info("wger: {} de {} exercicios baixados", all.size(), page.count());
            offset += pageSize;
            if (page.next() == null || all.size() >= max || offset >= page.count()) {
                break;
            }
        }
        return all;
    }

    private <T> Page<T> page(String uri, ParameterizedTypeReference<Page<T>> type) {
        return client.get().uri(uri).retrieve().body(type);
    }
}
