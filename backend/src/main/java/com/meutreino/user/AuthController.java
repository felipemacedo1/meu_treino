package com.meutreino.user;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.security.AuthPrincipal;
import com.meutreino.user.dto.AuthDtos.AuthResponse;
import com.meutreino.user.dto.AuthDtos.LoginRequest;
import com.meutreino.user.dto.AuthDtos.RegisterRequest;
import com.meutreino.user.dto.AuthDtos.UserDto;

import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Autenticacao")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/me")
    public UserDto me(@AuthenticationPrincipal AuthPrincipal principal) {
        return authService.me(principal.userId());
    }
}
