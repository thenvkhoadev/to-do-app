package vti.dtn.thenvkhoadev.authservice.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import vti.dtn.thenvkhoadev.authservice.dto.request.LoginRequest;
import vti.dtn.thenvkhoadev.authservice.dto.response.LoginResponse;
import vti.dtn.thenvkhoadev.authservice.dto.response.VerifyTokenResponse;
import vti.dtn.thenvkhoadev.authservice.entity.UserEntity;
import vti.dtn.thenvkhoadev.authservice.repository.UserRepository;

import java.util.Base64;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthenticationService {
    private static final int TOKEN_INDEX = 7;

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public LoginResponse login(LoginRequest loginRequest) {
        String username = loginRequest.getUsername();
        String password = loginRequest.getPassword();

        Optional<UserEntity> userEntity = userRepository.findByUsername(username);
        if (userEntity.isEmpty()){
            return LoginResponse.builder()
                    .status(404)
                    .message("User not found")
                    .build();
        }


        UsernamePasswordAuthenticationToken authToken =
                new UsernamePasswordAuthenticationToken(username, password);

        authenticationManager.authenticate(authToken);

        UserEntity user = userEntity.get();
        String accessToken = jwtService.generateToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        user.setAccessToken(accessToken);
        user.setRefreshToken(refreshToken);

        userRepository.save(user);

        return LoginResponse.builder()
                .status(200)
                .message("Login successful")
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .build();
    }

    public LoginResponse refreshToken(String authHeader) {
        if (!StringUtils.hasText(authHeader) || !authHeader.startsWith("Bearer ")) {
            return LoginResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Invalid token")
                    .build();
        }
        String refreshToken = authHeader.substring(TOKEN_INDEX);
        if( !jwtService.verifyToken(refreshToken)) {
            return LoginResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Invalid refresh token")
                    .build();
        }

        log.info("Refreshing token for: {}", refreshToken);
        String username = jwtService.extractUsername(refreshToken);
        Optional<UserEntity> userFoundByUsername = userRepository.findByUsername(username);
        if (userFoundByUsername.isEmpty()) {
            return LoginResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Token revoked")
                    .build();
        }

        UserEntity userEntity = userFoundByUsername.get();
        String accessToken = jwtService.generateToken(userEntity);
        String newRefreshToken = jwtService.generateRefreshToken(userEntity);

        userEntity.setAccessToken(accessToken);
        userEntity.setRefreshToken(newRefreshToken);
        userRepository.save(userEntity);

        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(userEntity.getId())
                .message("Refresh token successfully")
                .status(HttpStatus.OK.value())
                .build();
    }

    public VerifyTokenResponse verifyToken(String authHeader) {
        log.info("verifyToken|authHeader: {}", authHeader);

        if (!StringUtils.hasText(authHeader) || !authHeader.startsWith("Bearer ")) {
            log.error("verifyToken|Authorization header is missing or invalid");
            return VerifyTokenResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Invalid token")
                    .build();
        }

        String token = authHeader.substring(TOKEN_INDEX);
        if (!jwtService.verifyToken(token)) {
            log.error("verifyToken|Invalid token");
            return VerifyTokenResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Invalid token")
                    .build();
        }

        String username = jwtService.extractUsername(token);
        Optional<UserEntity> userFoundByUsername = userRepository.findByUsername(username);
        if (userFoundByUsername.isEmpty()) {
            log.error("verifyToken|User not found for username: {}", username);
            return VerifyTokenResponse.builder()
                    .status(HttpStatus.UNAUTHORIZED.value())
                    .message("Token revoked")
                    .build();
        }

        String role = userFoundByUsername.get().getRole().name();
        String userInfoStr = username + ":" + role;
        String xUserToken = Base64.getEncoder().encodeToString(userInfoStr.getBytes());

        log.info("verifyToken|X-User-Token: {}", xUserToken);

        return VerifyTokenResponse.builder()
                .status(HttpStatus.OK.value())
                .message("Success")
                .xUserToken(xUserToken)
                .build();
    }
}
