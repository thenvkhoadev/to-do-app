package com.todoapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
public class TaskRequest {
    @NotBlank
    @Size(max = 255)
    private String title;

    private String description;

    private String status = "todo";     // todo | in_progress | done

    private String priority = "medium"; // low | medium | high | urgent

    private OffsetDateTime dueDate;

    private String[] tags = new String[0];
}
