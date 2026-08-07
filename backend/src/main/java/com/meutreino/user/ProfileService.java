package com.meutreino.user;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.user.dto.ProfileDtos.BodyWeightHistory;
import com.meutreino.user.dto.ProfileDtos.BodyWeightPoint;
import com.meutreino.user.dto.ProfileDtos.BodyWeightRequest;
import com.meutreino.user.dto.ProfileDtos.ProfileDto;
import com.meutreino.user.dto.ProfileDtos.ProfileUpdateRequest;

@Service
public class ProfileService {

    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;
    private final BodyWeightRepository bodyWeightRepository;

    public ProfileService(UserRepository userRepository,
                          ProfileRepository profileRepository,
                          BodyWeightRepository bodyWeightRepository) {
        this.userRepository = userRepository;
        this.profileRepository = profileRepository;
        this.bodyWeightRepository = bodyWeightRepository;
    }

    @Transactional
    public ProfileDto get(Long userId) {
        User user = requireUser(userId);
        Profile profile = profileRepository.findById(userId).orElseGet(() -> {
            Profile created = new Profile();
            created.setUserId(userId);
            created.setWeeklyGoal(4);
            return profileRepository.save(created);
        });
        return toDto(user, profile);
    }

    @Transactional
    public ProfileDto update(Long userId, ProfileUpdateRequest request) {
        User user = requireUser(userId);
        Profile profile = profileRepository.findById(userId).orElseGet(() -> {
            Profile created = new Profile();
            created.setUserId(userId);
            return created;
        });

        if (request.name() != null && !request.name().isBlank()) {
            user.setName(request.name().trim());
            userRepository.save(user);
        }
        if (request.weightKg() != null) {
            profile.setWeightKg(request.weightKg());
            upsertBodyWeight(userId, request.weightKg(), LocalDate.now());
        }
        if (request.heightCm() != null) {
            profile.setHeightCm(request.heightCm());
        }
        if (request.birthDate() != null) {
            profile.setBirthDate(request.birthDate());
        }
        if (request.gender() != null) {
            profile.setGender(request.gender());
        }
        if (request.goal() != null) {
            profile.setGoal(request.goal());
        }
        if (request.experience() != null) {
            profile.setExperience(request.experience());
        }
        if (request.availableDays() != null) {
            profile.setAvailableDays(request.availableDays());
        }
        if (request.sessionMinutes() != null) {
            profile.setSessionMinutes(request.sessionMinutes());
        }
        if (request.weeklyGoal() != null) {
            profile.setWeeklyGoal(request.weeklyGoal());
        }
        profile.setUpdatedAt(Instant.now());
        profileRepository.save(profile);
        return toDto(user, profile);
    }

    @Transactional
    public BodyWeightHistory addBodyWeight(Long userId, BodyWeightRequest request) {
        LocalDate date = request.measuredAt() == null ? LocalDate.now() : request.measuredAt();
        upsertBodyWeight(userId, request.weightKg(), date);
        Profile profile = profileRepository.findById(userId).orElseGet(() -> {
            Profile created = new Profile();
            created.setUserId(userId);
            return created;
        });
        if (!date.isAfter(LocalDate.now())) {
            profile.setWeightKg(request.weightKg());
            profile.setUpdatedAt(Instant.now());
            profileRepository.save(profile);
        }
        return bodyWeightHistory(userId);
    }

    @Transactional(readOnly = true)
    public BodyWeightHistory bodyWeightHistory(Long userId) {
        return new BodyWeightHistory(bodyWeightRepository.findByUserIdOrderByMeasuredAtAsc(userId).stream()
                .map(bw -> new BodyWeightPoint(bw.getMeasuredAt(), bw.getWeightKg()))
                .toList());
    }

    private void upsertBodyWeight(Long userId, BigDecimal weight, LocalDate date) {
        BodyWeight entity = bodyWeightRepository.findByUserIdAndMeasuredAt(userId, date)
                .orElseGet(() -> {
                    BodyWeight created = new BodyWeight();
                    created.setUserId(userId);
                    created.setMeasuredAt(date);
                    return created;
                });
        entity.setWeightKg(weight);
        bodyWeightRepository.save(entity);
    }

    private User requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuario nao encontrado"));
    }

    private ProfileDto toDto(User user, Profile profile) {
        Double bmi = null;
        if (profile.getWeightKg() != null && profile.getHeightCm() != null && profile.getHeightCm() > 0) {
            double heightM = profile.getHeightCm() / 100.0;
            bmi = BigDecimal.valueOf(profile.getWeightKg().doubleValue() / (heightM * heightM))
                    .setScale(1, RoundingMode.HALF_UP)
                    .doubleValue();
        }
        return new ProfileDto(
                user.getId(),
                user.getName(),
                user.getEmail(),
                profile.getWeightKg(),
                profile.getHeightCm(),
                profile.getBirthDate(),
                profile.getGender(),
                profile.getGoal(),
                profile.getExperience(),
                profile.getAvailableDays(),
                profile.getSessionMinutes(),
                profile.getWeeklyGoal(),
                bmi);
    }
}
