package vti.dtn.thenvkhoadev.authservice.service;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import vti.dtn.thenvkhoadev.authservice.dto.request.RegisterRequest;
import vti.dtn.thenvkhoadev.authservice.dto.response.RegisterResponse;
import vti.dtn.thenvkhoadev.authservice.entity.UserEntity;
import vti.dtn.thenvkhoadev.authservice.enums.Role;
import vti.dtn.thenvkhoadev.authservice.repository.UserRepository;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public RegisterResponse registerUser(RegisterRequest request) {
        // Registration logic here
        String email = request.getEmail();
        String username = request.getUsername();
        String password = request.getPassword();
        String role = request.getRole();
        String firstName = request.getFirstName();
        String lastName = request.getLastName();

        Optional<UserEntity> userEntityByEmail = userRepository.findByEmail(email);
        Optional<UserEntity> userEntityByUsername = userRepository.findByUsername(username);

        if (userEntityByEmail.isPresent() || userEntityByUsername.isPresent()) {
            return RegisterResponse.builder()
                    .status(HttpStatus.BAD_REQUEST.value())
                    .message("Email or Username already exists")
                    .build();
        }

        UserEntity userEntity = UserEntity.builder()
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(password)) // Encrypt the password
                .role(Role.toEnum(role)) // Convert String to Role enum
                .firstName(firstName)
                .lastName(lastName)
                .build();

        userRepository.save(userEntity);

        return RegisterResponse.builder()
                .status(HttpStatus.OK.value())
                .message("User registered successfully")
                .build();
    }

    public UserEntity findByUsername(String username) {
        Optional<UserEntity> userOptional = userRepository.findByUsername(username);
        return userOptional.orElse(null);
    }
}
