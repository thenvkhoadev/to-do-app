package com.todoapp.controller;

import com.todoapp.dto.TaskRequest;
import com.todoapp.entity.Task;
import com.todoapp.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    // GET /api/tasks  –  get all tasks (or filtered by status)
    @GetMapping
    public ResponseEntity<List<Task>> getTasks(
            @AuthenticationPrincipal UserDetails user,
            @RequestParam(required = false) String status) {

        if (status != null) {
            return ResponseEntity.ok(taskService.getUserTasksByStatus(user.getUsername(), status));
        }
        return ResponseEntity.ok(taskService.getUserTasks(user.getUsername()));
    }

    // POST /api/tasks  –  create task
    @PostMapping
    public ResponseEntity<Task> createTask(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody TaskRequest request) {
        Task task = taskService.createTask(user.getUsername(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(task);
    }

    // PUT /api/tasks/{id}  –  update task
    @PutMapping("/{id}")
    public ResponseEntity<Task> updateTask(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable UUID id,
            @Valid @RequestBody TaskRequest request) {
        Task task = taskService.updateTask(user.getUsername(), id, request);
        return ResponseEntity.ok(task);
    }

    // DELETE /api/tasks/{id}  –  delete task
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable UUID id) {
        taskService.deleteTask(user.getUsername(), id);
        return ResponseEntity.noContent().build();
    }

    // GET /api/tasks/stats  –  statistics
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Long>> getStats(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(taskService.getTaskStats(user.getUsername()));
    }
}
