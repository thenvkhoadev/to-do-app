package com.todoapp.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Slf4j
@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private long refreshExpiration;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    // ===== Create Access Token (Supabase-like) =====
    public String generateToken(Authentication authentication) {
        UserDetails userPrincipal = (UserDetails) authentication.getPrincipal();
        // Check if the userPrincipal is our User entity, and use its ID
        if (userPrincipal instanceof com.todoapp.entity.User user) {
            java.util.Map<String, Object> metadata = new java.util.HashMap<>();
            metadata.put("username", user.getCustomUsername());
            metadata.put("user_name", user.getCustomUsername());
            metadata.put("full_name", user.getFullName());
            metadata.put("avatar_url", user.getAvatarUrl());
            return generateToken(user.getId().toString(), user.getEmail(), metadata);
        }
        return generateTokenFromEmail(userPrincipal.getUsername());
    }

    public String generateTokenFromEmail(String email) {
        return Jwts.builder()
                .subject(email)
                .claim("email", email)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSigningKey(), Jwts.SIG.HS256)
                .compact();
    }

    public String generateToken(String userId, String email, java.util.Map<String, Object> userMetadata) {
        return Jwts.builder()
                .subject(userId)
                .claim("email", email)
                .claim("user_metadata", userMetadata)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSigningKey(), Jwts.SIG.HS256)
                .compact();
    }

    // ===== Create Refresh Token =====
    public String generateRefreshToken(String email) {
        return Jwts.builder()
                .subject(email)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + refreshExpiration))
                .claim("type", "refresh")
                .signWith(getSigningKey(), Jwts.SIG.HS256)
                .compact();
    }

    // ===== Get Subject (User UUID) from token =====
    public String getSubjectFromToken(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }

    // ===== Get email from token =====
    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        
        String sub = claims.getSubject();
        if (sub != null && sub.contains("@")) {
            return sub; // Fallback for email-as-subject tokens
        }
        return claims.get("email", String.class);
    }

    // ===== Get User Metadata from token =====
    @SuppressWarnings("unchecked")
    public java.util.Map<String, Object> getUserMetadata(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            
            return claims.get("user_metadata", java.util.Map.class);
        } catch (Exception e) {
            log.warn("Failed to parse user_metadata claim: {}", e.getMessage());
            return null;
        }
    }

    // ===== Validate Token =====
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (MalformedJwtException e) {
            log.error("Invalid JWT token: {}", e.getMessage());
        } catch (ExpiredJwtException e) {
            log.error("JWT token is expired: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            log.error("JWT token is unsupported: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            log.error("JWT claims string is empty: {}", e.getMessage());
        }
        return false;
    }
}
