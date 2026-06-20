package com.todoapp.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final com.todoapp.repository.UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String token = parseJwt(request);

        if (token != null && jwtTokenProvider.validateToken(token)) {
            String subject = jwtTokenProvider.getSubjectFromToken(token);
            String email = jwtTokenProvider.getEmailFromToken(token);

            com.todoapp.entity.User user = null;
            try {
                if (subject != null && !subject.contains("@")) {
                    user = userRepository.findById(java.util.UUID.fromString(subject)).orElse(null);
                }
            } catch (IllegalArgumentException e) {
                // Subject is not a UUID
            }

            if (user == null && email != null) {
                user = userRepository.findByEmail(email).orElse(null);
            }

            // If user is not found, provision them (social registration)
            if (user == null) {
                user = provisionUser(subject, email, jwtTokenProvider.getUserMetadata(token));
            }

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            user,
                            null,
                            user.getAuthorities()
                    );
            authentication.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
        }

        filterChain.doFilter(request, response);
    }

    private com.todoapp.entity.User provisionUser(String subject, String email, java.util.Map<String, Object> metadata) {
        log.info("Auto-provisioning user from OAuth2 token: subject={}, email={}", subject, email);
        
        java.util.UUID userId;
        try {
            userId = java.util.UUID.fromString(subject);
        } catch (Exception e) {
            userId = java.util.UUID.randomUUID();
        }

        String fullName = null;
        String avatarUrl = null;
        String username = null;
        
        if (metadata != null) {
            fullName = (String) metadata.get("full_name");
            avatarUrl = (String) metadata.get("avatar_url");
            username = (String) metadata.get("user_name");
        }
        
        if (username == null || username.trim().isEmpty()) {
            if (email != null) {
                username = email.split("@")[0];
            } else {
                username = "user_" + userId.toString().substring(0, 8);
            }
        }
        
        // Prevent username duplication
        int count = 1;
        String baseUsername = username;
        while (userRepository.existsByUsername(username)) {
            username = baseUsername + "_" + count++;
        }

        com.todoapp.entity.User newUser = com.todoapp.entity.User.builder()
                .id(userId)
                .email(email != null ? email : userId.toString() + "@oauth.todoapp")
                .username(username)
                .fullName(fullName != null ? fullName : username)
                .avatarUrl(avatarUrl)
                .role("user")
                .tier("free")
                .level(1)
                .currentXp(0)
                .totalXp(0)
                .nextLevelXp(50)
                .rankName("Rookie")
                .rankDivision("V")
                .rankTitle("Rookie V")
                .focusScore(0)
                .streakDays(0)
                .totalTasks(0)
                .completedTasks(0)
                .focusHours(0)
                .themeMode("dark")
                .notificationsEnabled(true)
                .privacyMode(false)
                .coreTech(new String[0])
                .build();

        return userRepository.save(newUser);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");
        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }
        return null;
    }
}
