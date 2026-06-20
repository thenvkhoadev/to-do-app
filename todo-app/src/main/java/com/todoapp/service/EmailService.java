package com.todoapp.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    public void sendOtp(String email, String otp, String purpose) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(email);
            helper.setSubject("Todo App OTP Verification - [" + purpose + "]");

            String emailContent = "<html>" +
                    "<body style=\"font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f6; padding: 40px; margin: 0;\">" +
                    "  <div style=\"max-width: 500px; background-color: #ffffff; margin: 0 auto; padding: 40px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); text-align: center;\">" +
                    "    <h2 style=\"color: #1a1a1a; margin-bottom: 8px; font-weight: 600;\">Confirm Your Email Address</h2>" +
                    "    <p style=\"color: #666666; font-size: 15px; margin-bottom: 30px;\">You are performing <strong>" + purpose + "</strong> on your Todo App account. Use the verification code below:</p>" +
                    "    <div style=\"display: inline-block; background-color: #f1f3f9; color: #3b52e2; font-size: 32px; font-weight: 700; letter-spacing: 6px; padding: 16px 36px; border-radius: 8px; margin-bottom: 30px; border: 1px solid #e1e4e8;\">" +
                    "      " + otp + "" +
                    "    </div>" +
                    "    <p style=\"color: #999999; font-size: 13px; line-height: 1.5;\">This OTP is valid for <strong>5 minutes</strong>. If you did not make this request, you can safely ignore this email.</p>" +
                    "    <hr style=\"border: none; border-top: 1px solid #eeeeee; margin: 30px 0;\">" +
                    "    <p style=\"color: #cccccc; font-size: 11px;\">© 2026 Todo App Inc. All rights reserved.</p>" +
                    "  </div>" +
                    "</body>" +
                    "</html>";

            helper.setText(emailContent, true);
            mailSender.send(message);
            log.info("Successfully sent OTP email to {} for purpose {}", email, purpose);
        } catch (MessagingException e) {
            log.error("Failed to send Mime email to {}. Falling back to plain text.", email, e);
            sendPlainOtp(email, otp, purpose);
        } catch (Exception e) {
            log.error("Unexpected error occurred while sending OTP email to {}", email, e);
            throw new RuntimeException("Could not send verification email: " + e.getMessage());
        }
    }

    private void sendPlainOtp(String email, String otp, String purpose) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(email);
            message.setSubject("Todo App OTP Verification - [" + purpose + "]");
            message.setText("Your OTP verification code for " + purpose + " is: " + otp + "\nThis code is valid for 5 minutes.");
            mailSender.send(message);
            log.info("Successfully sent plain text OTP email to {}", email);
        } catch (Exception e) {
            log.error("Failed to send plain text email to {}", email, e);
            throw new RuntimeException("Could not send verification email: " + e.getMessage());
        }
    }
}
