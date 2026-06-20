package com.todoapp.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "email_otps", schema = "public")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmailOtp {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "otp_code", nullable = false, length = 10)
    private String otpCode;

    @Column(name = "verified")
    @Builder.Default
    private Boolean verified = false;

    @Column(name = "attempt_count")
    @Builder.Default
    private Integer attemptCount = 0;

    @Column(name = "purpose")
    @Builder.Default
    private String purpose = "LOGIN";

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "expired_at", nullable = false)
    private OffsetDateTime expiredAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
        if (verified == null) {
            verified = false;
        }
        if (attemptCount == null) {
            attemptCount = 0;
        }
        if (purpose == null) {
            purpose = "LOGIN";
        }
    }
}
