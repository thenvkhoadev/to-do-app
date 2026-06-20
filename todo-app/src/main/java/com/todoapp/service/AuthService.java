package com.todoapp.service;

import com.todoapp.dto.*;
import com.todoapp.entity.*;
import com.todoapp.repository.*;
import com.todoapp.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.UUID;
import java.util.Map;
import java.util.HashMap;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final OtpService otpService;
    private final UserSessionRepository userSessionRepository;
    private final AuditLogRepository auditLogRepository;
    private final EntityManager entityManager;
    private final PasswordEncoder passwordEncoder;

    public void sendOtp(SendOtpRequest request) {
        String email = request.getEmail();
        String purpose = request.getPurpose() == null ? "LOGIN" : request.getPurpose().toUpperCase();

        if ("SIGNUP".equals(purpose)) {
            if (userRepository.existsByEmail(email)) {
                throw new RuntimeException("Email is already registered. Please login instead.");
            }
        } else if ("LOGIN".equals(purpose) || "FORGOT_PASSWORD".equals(purpose)) {
            if (!userRepository.existsByEmail(email)) {
                throw new RuntimeException("Email is not registered. Please sign up first.");
            }
        }

        otpService.generateAndSendOtp(email, purpose);
    }

    @Transactional
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        String email = request.getEmail();
        String otp = request.getOtp();
        String purpose = request.getPurpose() == null ? "LOGIN" : request.getPurpose().toUpperCase();

        // 1. Verify OTP
        otpService.verifyOtp(email, otp, purpose);

        // 2. Handle User Creation/Retrieval based on purpose
        User user;
        if ("SIGNUP".equals(purpose)) {
            boolean existsInPublic = userRepository.existsByEmail(email);

            Number authCount = (Number) entityManager.createNativeQuery("SELECT count(*) FROM auth.users WHERE email = :email")
                    .setParameter("email", email)
                    .getSingleResult();
            boolean existsInAuth = authCount.longValue() > 0;

            if (existsInPublic) {
                throw new RuntimeException("Email is already registered. Please login instead.");
            }

            if (existsInAuth) {
                // Orphan state: exists in auth.users but not in public.users.
                // Automatically heal by deleting the orphan in auth.users first, so the signup can proceed cleanly.
                entityManager.createNativeQuery("DELETE FROM auth.users WHERE email = :email")
                        .setParameter("email", email)
                        .executeUpdate();
            }

            String username = request.getUsername() != null && !request.getUsername().isBlank()
                    ? request.getUsername() : email.split("@")[0];
            String fullName = request.getFullName() != null && !request.getFullName().isBlank()
                    ? request.getFullName() : email.split("@")[0];

            UUID userId = UUID.randomUUID();

            try {
                // Serialize user metadata to JSON
                Map<String, String> metadata = new HashMap<>();
                metadata.put("username", username);
                metadata.put("full_name", fullName);
                String userMetadataJson = new ObjectMapper().writeValueAsString(metadata);

                String rawPassword = request.getPassword();
                String passwordHash = (rawPassword != null && !rawPassword.isBlank())
                        ? passwordEncoder.encode(rawPassword)
                        : "$2a$10$dummybcryptpasswordhashforsecurityotpworkflow";

                // Insert user record into auth.users first
                entityManager.createNativeQuery(
                    "INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, role, aud, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, is_anonymous) " +
                    "VALUES (:id, :email, :password, NOW(), 'authenticated', 'authenticated', cast(:appMetadata as jsonb), cast(:userMetadata as jsonb), false, NOW(), NOW(), false)"
                )
                .setParameter("id", userId)
                .setParameter("email", email)
                .setParameter("password", passwordHash)
                .setParameter("appMetadata", "{\"provider\": \"email\", \"providers\": [\"email\"]}")
                .setParameter("userMetadata", userMetadataJson)
                .executeUpdate();

            } catch (Exception e) {
                throw new RuntimeException("Failed to register auth identity: " + e.getMessage(), e);
            }

            // Retrieve the user from public.users (which was populated by the Postgres trigger)
            user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Failed to retrieve registered user profile"));

            auditLogRepository.save(AuditLog.builder()
                    .user(user)
                    .action("SIGNUP")
                    .description("User signed up successfully via Email OTP.")
                    .build());
        } else {
            user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found: " + email));

            auditLogRepository.save(AuditLog.builder()
                    .user(user)
                    .action(purpose)
                    .description("User verified OTP successfully for " + purpose)
                    .build());
        }

        // 3. Issue JWT & Refresh Token (Supabase compatible)
        Map<String, Object> tokenMetadata = new HashMap<>();
        tokenMetadata.put("username", user.getCustomUsername());
        tokenMetadata.put("user_name", user.getCustomUsername());
        tokenMetadata.put("full_name", user.getFullName());
        tokenMetadata.put("avatar_url", user.getAvatarUrl());

        String accessToken = jwtTokenProvider.generateToken(user.getId().toString(), user.getEmail(), tokenMetadata);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        // 4. Save Session
        UserSession session = UserSession.builder()
                .user(user)
                .deviceName(request.getDeviceName())
                .deviceOs(request.getDeviceOs())
                .ipAddress(request.getIpAddress())
                .refreshToken(refreshToken)
                .accessToken(accessToken)
                .isActive(true)
                .build();
        userSessionRepository.save(session);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(86400)
                .user(mapToProfileResponse(user))
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // Find the user by email or username
        User user = userRepository.findByEmail(request.getEmail())
                .or(() -> userRepository.findByUsername(request.getEmail()))
                .orElseThrow(() -> new RuntimeException("User not found: " + request.getEmail()));

        // In a production Supabase integration, authentication is performed via the Supabase client library,
        // and the client sends the Supabase JWT. For this Spring Security demo backend, 
        // we authenticate the user and issue the JWT directly based on their email if it exists in DB.
        Map<String, Object> tokenMetadata = new HashMap<>();
        tokenMetadata.put("username", user.getCustomUsername());
        tokenMetadata.put("user_name", user.getCustomUsername());
        tokenMetadata.put("full_name", user.getFullName());
        tokenMetadata.put("avatar_url", user.getAvatarUrl());

        String accessToken = jwtTokenProvider.generateToken(user.getId().toString(), user.getEmail(), tokenMetadata);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        // Save Session
        UserSession session = UserSession.builder()
                .user(user)
                .refreshToken(refreshToken)
                .accessToken(accessToken)
                .isActive(true)
                .build();
        userSessionRepository.save(session);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(86400)
                .user(mapToProfileResponse(user))
                .build();
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }
        String email = jwtTokenProvider.getEmailFromToken(refreshToken);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<String, Object> tokenMetadata = new HashMap<>();
        tokenMetadata.put("username", user.getCustomUsername());
        tokenMetadata.put("user_name", user.getCustomUsername());
        tokenMetadata.put("full_name", user.getFullName());
        tokenMetadata.put("avatar_url", user.getAvatarUrl());

        String newAccessToken = jwtTokenProvider.generateToken(user.getId().toString(), email, tokenMetadata);

        // Update active session with the new access token
        userSessionRepository.findByRefreshToken(refreshToken).ifPresent(session -> {
            session.setAccessToken(newAccessToken);
            session.setLastActiveAt(java.time.OffsetDateTime.now());
            userSessionRepository.save(session);
        });

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(refreshToken) // reuse same refresh token
                .tokenType("Bearer")
                .expiresIn(86400)
                .user(mapToProfileResponse(user))
                .build();
    }

    public String resolveEmail(String identifier) {
        if (identifier == null) {
            return null;
        }
        if (identifier.contains("@")) {
            return identifier;
        }
        return userRepository.findByUsername(identifier)
                .map(User::getEmail)
                .orElse(identifier);
    }

    private UserProfileResponse mapToProfileResponse(User user) {
        return UserProfileResponse.builder()
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
                .build();
    }
}
