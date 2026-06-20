package vti.dtn.thenvkhoadev.authservice.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Builder
@Setter
public class LoginResponse {
    private int status;
    private String message;

    private Long userId;
    private String accessToken;
    private String refreshToken;
}
