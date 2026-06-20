package com.todoapp.repository;

import com.todoapp.entity.EmailOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EmailOtpRepository extends JpaRepository<EmailOtp, UUID> {

    Optional<EmailOtp> findTopByEmailOrderByCreatedAtDesc(String email);

    Optional<EmailOtp> findTopByEmailAndPurposeOrderByCreatedAtDesc(String email, String purpose);

    @Transactional
    @Modifying
    @Query("DELETE FROM EmailOtp e WHERE e.expiredAt < :now")
    void deleteExpiredOtps(OffsetDateTime now);
}
