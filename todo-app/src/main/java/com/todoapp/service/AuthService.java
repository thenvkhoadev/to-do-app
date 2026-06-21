package com.todoapp.service;

import com.todoapp.entity.User;
import com.todoapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;

    public String resolveEmail(String identifier) {
        if (identifier == null) {
            return null;
        }
        if (identifier.contains("@")) {
            return identifier;
        }
        return userRepository.findByUsername(identifier)
                .map(User::getEmail)
                .orElse(identifier);
    }
}
