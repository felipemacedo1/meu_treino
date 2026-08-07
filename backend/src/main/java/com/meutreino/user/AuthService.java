package com.meutreino.user;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.ConflictException;
import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.common.ApiExceptions.UnauthorizedException;
import com.meutreino.security.JwtService;
import com.meutreino.user.dto.AuthDtos.AuthResponse;
import com.meutreino.user.dto.AuthDtos.LoginRequest;
import com.meutreino.user.dto.AuthDtos.RegisterRequest;
import com.meutreino.user.dto.AuthDtos.UserDto;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       ProfileRepository profileRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase();
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("Ja existe uma conta com esse e-mail");
        }
        User user = new User();
        user.setName(request.name().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        userRepository.save(user);

        Profile profile = new Profile();
        profile.setUserId(user.getId());
        profile.setWeeklyGoal(4);
        profileRepository.save(profile);

        return buildResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailIgnoreCase(request.email().trim())
                .orElseThrow(() -> new UnauthorizedException("E-mail ou senha invalidos"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("E-mail ou senha invalidos");
        }
        return buildResponse(user);
    }

    @Transactional(readOnly = true)
    public UserDto me(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuario nao encontrado"));
        return toDto(user);
    }

    private AuthResponse buildResponse(User user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthResponse(token, "Bearer", jwtService.expiresInSeconds(), toDto(user));
    }

    private UserDto toDto(User user) {
        return new UserDto(user.getId(), user.getName(), user.getEmail(), user.getCreatedAt());
    }
}
