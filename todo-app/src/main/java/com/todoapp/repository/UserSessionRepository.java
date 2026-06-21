package com.todoapp.repository;

import com.todoapp.entity.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, UUID> {
    List<UserSession> findByUserIdAndIsActiveTrue(UUID userId);
    Optional<UserSession> findByRefreshToken(String refreshToken);
    Optional<UserSession> findByAccessToken(String accessToken);
    Optional<UserSession> findFirstByUserAndDeviceNameAndDeviceOs(com.todoapp.entity.User user, String deviceName, String deviceOs);
}

