package com.todoapp.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_sessions", schema = "public")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_name")
    private String deviceName;

    @Column(name = "device_os")
    private String deviceOs;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "refresh_token", columnDefinition = "text")
    private String refreshToken;

    @Column(name = "access_token", columnDefinition = "text")
    private String accessToken;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "last_active_at")
    private OffsetDateTime lastActiveAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        lastActiveAt = OffsetDateTime.now();
        if (isActive == null) {
            isActive = true;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        lastActiveAt = OffsetDateTime.now();
    }
}
