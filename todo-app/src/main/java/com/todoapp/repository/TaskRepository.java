package com.todoapp.repository;

import com.todoapp.entity.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TaskRepository extends JpaRepository<Task, UUID> {

    List<Task> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Page<Task> findByUserId(UUID userId, Pageable pageable);

    List<Task> findByUserIdAndStatus(UUID userId, String status);

    Optional<Task> findByIdAndUserId(UUID id, UUID userId);

    @Query("SELECT t FROM Task t WHERE t.user.id = :userId AND t.title LIKE %:keyword%")
    List<Task> searchByUserIdAndTitle(@Param("userId") UUID userId,
                                      @Param("keyword") String keyword);

    long countByUserIdAndStatus(UUID userId, String status);
}
