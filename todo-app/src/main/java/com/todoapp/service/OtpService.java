package com.todoapp.service;

import com.todoapp.entity.EmailOtp;
import com.todoapp.repository.EmailOtpRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final EmailOtpRepository emailOtpRepository;
    private final EmailService emailService;
    private static final SecureRandom secureRandom = new SecureRandom();

    private static final int OTP_EXPIRY_MINUTES = 5;
    private static final int MAX_ATTEMPTS = 5;
    private static final int SEND_COOLDOWN_SECONDS = 30;

    /**
     * Generates a 6-digit OTP code.
     */
    public String generateOtpCode() {
        int code = 100000 + secureRandom.nextInt(900000);
        return String.valueOf(code);
    }

    /**
     * Generates and sends OTP to the specified email.
     */
    @Transactional
    public void generateAndSendOtp(String email, String purpose) {
        String normalizedPurpose = (purpose == null || purpose.trim().isEmpty()) ? "LOGIN" : purpose.toUpperCase().trim();
        
        // 1. Check cooldown limit (1 request per 30 seconds)
        Optional<EmailOtp> latestOtpOpt = emailOtpRepository.findTopByEmailOrderByCreatedAtDesc(email);
        if (latestOtpOpt.isPresent()) {
            EmailOtp latestOtp = latestOtpOpt.get();
            OffsetDateTime cooldownTime = latestOtp.getCreatedAt().plusSeconds(SEND_COOLDOWN_SECONDS);
            if (OffsetDateTime.now().isBefore(cooldownTime)) {
                long secondsLeft = cooldownTime.toEpochSecond() - OffsetDateTime.now().toEpochSecond();
                throw new RuntimeException("Please wait " + secondsLeft + " seconds before requesting a new OTP.");
            }
        }

        // 2. Generate OTP Code
        String otpCode = generateOtpCode();

        // 3. Save OTP to DB
        EmailOtp otpEntity = EmailOtp.builder()
                .email(email)
                .otpCode(otpCode)
                .verified(false)
                .attemptCount(0)
                .purpose(normalizedPurpose)
                .expiredAt(OffsetDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES))
                .build();

        emailOtpRepository.save(otpEntity);

        // 4. Send Email
        emailService.sendOtp(email, otpCode, normalizedPurpose);
    }

    /**
     * Verifies the OTP code for the given email and purpose.
     */
    @Transactional
    public boolean verifyOtp(String email, String rawCode, String purpose) {
        String normalizedPurpose = (purpose == null || purpose.trim().isEmpty()) ? "LOGIN" : purpose.toUpperCase().trim();
        
        EmailOtp otpEntity = emailOtpRepository
                .findTopByEmailAndPurposeOrderByCreatedAtDesc(email, normalizedPurpose)
                .orElseThrow(() -> new RuntimeException("No OTP code has been requested for this email."));

        // 1. Check if already verified
        if (Boolean.TRUE.equals(otpEntity.getVerified())) {
            throw new RuntimeException("This OTP has already been verified.");
        }

        // 2. Check if expired
        if (OffsetDateTime.now().isAfter(otpEntity.getExpiredAt())) {
            throw new RuntimeException("OTP has expired. Please request a new one.");
        }

        // 3. Check attempts limit
        if (otpEntity.getAttemptCount() >= MAX_ATTEMPTS) {
            throw new RuntimeException("Too many failed attempts. Please request a new OTP.");
        }

        // 4. Validate OTP code
        if (!otpEntity.getOtpCode().equals(rawCode)) {
            // Increment attempt count
            otpEntity.setAttemptCount(otpEntity.getAttemptCount() + 1);
            emailOtpRepository.save(otpEntity);
            
            int attemptsRemaining = MAX_ATTEMPTS - otpEntity.getAttemptCount();
            if (attemptsRemaining <= 0) {
                throw new RuntimeException("Incorrect OTP. Too many failed attempts. Please request a new OTP.");
            } else {
                throw new RuntimeException("Incorrect OTP. " + attemptsRemaining + " attempts remaining.");
            }
        }

        // 5. Success
        otpEntity.setVerified(true);
        emailOtpRepository.save(otpEntity);
        log.info("Successfully verified OTP for email {} and purpose {}", email, normalizedPurpose);
        return true;
    }

    /**
     * Cron Job to automatically clean up expired OTPs from the database.
     * Runs every minute.
     */
    @Scheduled(cron = "0 * * * * *")
    public void cleanExpiredOtps() {
        try {
            emailOtpRepository.deleteExpiredOtps(OffsetDateTime.now());
            log.debug("Cleanup cron job executed: Deleted expired OTP codes.");
        } catch (Exception e) {
            log.error("Failed to clean up expired OTPs", e);
        }
    }
}
