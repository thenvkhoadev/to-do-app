package com.todoapp.repository;

import com.todoapp.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface TagRepository extends JpaRepository<Tag, UUID> {
    Optional<Tag> findByUserIdAndName(UUID userId, String name);
}