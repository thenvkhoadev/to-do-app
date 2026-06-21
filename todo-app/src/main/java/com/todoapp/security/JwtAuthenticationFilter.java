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

    private final SupabaseJwtValidator supabaseJwtValidator;
    private final com.todoapp.repository.UserRepository userRepository;
    private final com.todoapp.repository.UserSessionRepository userSessionRepository;
    private final com.todoapp.repository.AuditLogRepository auditLogRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String token = parseJwt(request);

        if (token != null) {
            try {
                String subject = supabaseJwtValidator.getUserId(token);
                String email = supabaseJwtValidator.getEmail(token);

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
                    user = provisionUser(subject, email, supabaseJwtValidator.getUserMetadata(token));
                }

                if (user != null) {
                    handleUserSession(user, token, request);

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
            } catch (Exception e) {
                log.error("Could not set user authentication in security context", e);
            }
        }

        filterChain.doFilter(request, response);
    }

    private void handleUserSession(com.todoapp.entity.User user, String token, HttpServletRequest request) {
        try {
            java.util.Optional<com.todoapp.entity.UserSession> sessionOpt = userSessionRepository.findByAccessToken(token);

            if (sessionOpt.isPresent()) {
                com.todoapp.entity.UserSession session = sessionOpt.get();
                session.setLastActiveAt(java.time.OffsetDateTime.now());
                userSessionRepository.save(session);
            } else {
                String deviceName = request.getHeader("X-Device-Name");
                if (deviceName == null || deviceName.trim().isEmpty()) {
                    deviceName = request.getHeader("User-Agent");
                }
                if (deviceName == null || deviceName.trim().isEmpty()) {
                    deviceName = "Unknown Device";
                }

                String deviceOs = request.getHeader("X-Device-OS");
                if (deviceOs == null || deviceOs.trim().isEmpty()) {
                    deviceOs = "unknown";
                }

                String ipAddress = request.getRemoteAddr();

                java.util.Optional<com.todoapp.entity.UserSession> existingSessionOpt =
                        userSessionRepository.findFirstByUserAndDeviceNameAndDeviceOs(user, deviceName, deviceOs);

                if (existingSessionOpt.isPresent()) {
                    com.todoapp.entity.UserSession existingSession = existingSessionOpt.get();
                    existingSession.setAccessToken(token);
                    existingSession.setIpAddress(ipAddress);
                    existingSession.setIsActive(true);
                    existingSession.setLastActiveAt(java.time.OffsetDateTime.now());
                    userSessionRepository.save(existingSession);
                    log.info("Updated existing user session for user={} on device={} ({})", user.getEmail(), deviceName, deviceOs);
                } else {
                    com.todoapp.entity.UserSession newSession = com.todoapp.entity.UserSession.builder()
                            .user(user)
                            .deviceName(deviceName)
                            .deviceOs(deviceOs)
                            .ipAddress(ipAddress)
                            .accessToken(token)
                            .isActive(true)
                            .build();
                    userSessionRepository.save(newSession);
                    log.info("Created new user session for user={} on device={} ({})", user.getEmail(), deviceName, deviceOs);
                }

                com.todoapp.entity.AuditLog auditLog = com.todoapp.entity.AuditLog.builder()
                        .user(user)
                        .action("LOGIN")
                        .description("User logged in successfully via Supabase JWT on " + deviceName + " (" + deviceOs + ").")
                        .build();
                auditLogRepository.save(auditLog);
            }
        } catch (Exception e) {
            log.error("Failed to handle user session and audit logging", e);
        }
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
