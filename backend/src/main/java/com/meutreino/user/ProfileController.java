package com.meutreino.user;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.security.AuthPrincipal;
import com.meutreino.user.dto.ProfileDtos.BodyWeightHistory;
import com.meutreino.user.dto.ProfileDtos.BodyWeightRequest;
import com.meutreino.user.dto.ProfileDtos.ProfileDto;
import com.meutreino.user.dto.ProfileDtos.ProfileUpdateRequest;

import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/profile")
@Tag(name = "Perfil")
public class ProfileController {

    private final ProfileService service;

    public ProfileController(ProfileService service) {
        this.service = service;
    }

    @GetMapping
    public ProfileDto get(@AuthenticationPrincipal AuthPrincipal principal) {
        return service.get(principal.userId());
    }

    @PutMapping
    public ProfileDto update(@AuthenticationPrincipal AuthPrincipal principal,
                             @Valid @RequestBody ProfileUpdateRequest request) {
        return service.update(principal.userId(), request);
    }

    @GetMapping("/body-weights")
    public BodyWeightHistory bodyWeights(@AuthenticationPrincipal AuthPrincipal principal) {
        return service.bodyWeightHistory(principal.userId());
    }

    @PostMapping("/body-weights")
    public BodyWeightHistory addBodyWeight(@AuthenticationPrincipal AuthPrincipal principal,
                                           @Valid @RequestBody BodyWeightRequest request) {
        return service.addBodyWeight(principal.userId(), request);
    }
}
