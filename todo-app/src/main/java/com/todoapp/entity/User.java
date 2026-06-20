package com.todoapp.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.OffsetDateTime;
import java.util.*;

@Entity
@Table(name = "users", schema = "public")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "username")
    private String username;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "bio")
    private String bio;

    @Column(name = "tier")
    @Builder.Default
    private String tier = "free";

    @Column(name = "role")
    @Builder.Default
    private String role = "user";

    // Stats
    @Column(name = "focus_score") @Builder.Default private Integer focusScore = 0;
    @Column(name = "streak_days") @Builder.Default private Integer streakDays = 0;
    @Column(name = "total_tasks") @Builder.Default private Integer totalTasks = 0;
    @Column(name = "completed_tasks") @Builder.Default private Integer completedTasks = 0;
    @Column(name = "focus_hours") @Builder.Default private Integer focusHours = 0;

    // Theme & Settings
    @Column(name = "theme_mode") @Builder.Default private String themeMode = "dark";
    @Column(name = "notifications_enabled") @Builder.Default private Boolean notificationsEnabled = true;
    @Column(name = "privacy_mode") @Builder.Default private Boolean privacyMode = false;

    // Rank & Level
    @Column(name = "level") @Builder.Default private Integer level = 1;
    @Column(name = "current_xp") @Builder.Default private Integer currentXp = 0;
    @Column(name = "total_xp") @Builder.Default private Integer totalXp = 0;
    @Column(name = "next_level_xp") @Builder.Default private Integer nextLevelXp = 50;
    @Column(name = "rank_name") @Builder.Default private String rankName = "Rookie";
    @Column(name = "rank_division") @Builder.Default private String rankDivision = "V";
    @Column(name = "rank_title") @Builder.Default private String rankTitle = "Rookie V";
    @Column(name = "streak_count") @Builder.Default private Integer streakCount = 0;
    @Column(name = "longest_streak") @Builder.Default private Integer longestStreak = 0;

    // Core tech (text array mapped via Hibernate 6)
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "core_tech", columnDefinition = "text[]")
    @Builder.Default
    private String[] coreTech = new String[0];

    @Column(name = "occupation") private String occupation;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    // ===== Spring Security UserDetails Implementation =====

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
    }

    @Override
    public String getPassword() {
        // Supabase manages passwords via auth.users
        // Spring Boot only verifies JWT, no password hash needed locally
        return null;
    }

    @Override
    public String getUsername() {
        return email; // Use email as username for Spring Security
    }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return true; }
}
