package com.todoapp.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@Component
public class SupabaseJwtValidator {

    @Value("${supabase.jwt.secret}")
    private String jwtSecret;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    public Claims validateAndGetClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String getUserId(String token) {
        return validateAndGetClaims(token).getSubject(); // "sub" claim = user UUID
    }

    public String getEmail(String token) {
        return validateAndGetClaims(token).get("email", String.class);
    }

    @SuppressWarnings("unchecked")
    public java.util.Map<String, Object> getUserMetadata(String token) {
        try {
            return validateAndGetClaims(token).get("user_metadata", java.util.Map.class);
        } catch (Exception e) {
            return null;
        }
    }
}
