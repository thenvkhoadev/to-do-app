package com.todoapp.controller;

import com.todoapp.dto.*;
import com.todoapp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @GetMapping("/resolve-email")
    public ResponseEntity<java.util.Map<String, String>> resolveEmail(@RequestParam String identifier) {
        String email = authService.resolveEmail(identifier);
        return ResponseEntity.ok(java.util.Map.of("email", email));
    }
}
