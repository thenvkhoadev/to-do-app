package com.todoapp.controller;

import com.todoapp.dto.SendOtpRequest;
import com.todoapp.dto.VerifyOtpRequest;
import com.todoapp.service.OtpService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
public class OtpController {

    private final OtpService otpService;

    @PostMapping("/send")
    public ResponseEntity<?> send(@Valid @RequestBody SendOtpRequest request) {
        otpService.generateAndSendOtp(request.getEmail(), request.getPurpose());
        return ResponseEntity.ok(Map.of("message", "OTP sent"));
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verify(@Valid @RequestBody VerifyOtpRequest request) {
        otpService.verifyOtp(request.getEmail(), request.getOtp(), request.getPurpose());
        // Chỉ xác nhận OTP đúng. KHÔNG tạo user, KHÔNG issue JWT ở đây.
        return ResponseEntity.ok(Map.of("verified", true));
    }
}
