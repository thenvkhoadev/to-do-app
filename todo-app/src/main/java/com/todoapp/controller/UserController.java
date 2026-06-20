package com.todoapp.controller;

import com.todoapp.dto.UserProfileResponse;
import com.todoapp.entity.User;
import com.todoapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    // GET /api/users/me  –  get information of the current authenticated user
    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getMe(
            @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(UserProfileResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getCustomUsername())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .tier(user.getTier())
                .role(user.getRole())
                .level(user.getLevel())
                .rankTitle(user.getRankTitle())
                .totalXp(user.getTotalXp())
                .streakCount(user.getStreakCount())
                .build()
        );
    }
}
