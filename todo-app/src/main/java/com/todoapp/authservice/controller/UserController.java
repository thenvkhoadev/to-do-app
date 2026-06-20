package vti.dtn.thenvkhoadev.authservice.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vti.dtn.thenvkhoadev.authservice.dto.request.RegisterRequest;
import vti.dtn.thenvkhoadev.authservice.dto.response.RegisterResponse;
import vti.dtn.thenvkhoadev.authservice.service.UserService;

@RestController
@RequiredArgsConstructor
@RequestMapping(path = "/api/v1/auth/users")
public class UserController {
    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<RegisterResponse> register(@RequestBody @Valid RegisterRequest request) {
        RegisterResponse response = userService.registerUser(request);
        return ResponseEntity
                .status(response.getStatus())
                .body(response);
    }
}
