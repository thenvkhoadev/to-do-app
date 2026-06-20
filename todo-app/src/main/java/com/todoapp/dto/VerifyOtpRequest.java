package com.todoapp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class VerifyOtpRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "OTP code is required")
    private String otp;

    private String purpose; // defaults to LOGIN if not provided

    private String deviceName;
    private String deviceOs;
    private String ipAddress;
    
    private String username;
    private String fullName;
    private String password;
}

