package vti.dtn.thenvkhoadev.authservice.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vti.dtn.thenvkhoadev.authservice.entity.UserEntity;
import vti.dtn.thenvkhoadev.authservice.service.UserService;

@RestController
@RequiredArgsConstructor
@RequestMapping(path = "/user")
public class CurrentUserController {
    private final UserService userService;

    @GetMapping("/me")
    public UserEntity getUser() {
        UserEntity user = null;
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            Object principal = authentication.getPrincipal();
            if (principal instanceof UserDetails userDetails) {
                String username = userDetails.getUsername();
                user = userService.findByUsername(username);
            }
        }

        return user;
    }
}
