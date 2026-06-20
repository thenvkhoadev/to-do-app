package com.todoapp.service;

import com.todoapp.dto.TaskRequest;
import com.todoapp.entity.Task;
import com.todoapp.entity.User;
import com.todoapp.repository.TaskRepository;
import com.todoapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    // Get all tasks for user
    public List<Task> getUserTasks(String email) {
        User user = getUserByEmail(email);
        return taskRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
    }

    // Get tasks by status
    public List<Task> getUserTasksByStatus(String email, String status) {
        User user = getUserByEmail(email);
        return taskRepository.findByUserIdAndStatus(user.getId(), status);
    }

    // Create task
    @Transactional
    public Task createTask(String email, TaskRequest request) {
        User user = getUserByEmail(email);

        Task task = Task.builder()
                .user(user)
                .title(request.getTitle())
                .description(request.getDescription())
                .status(request.getStatus())
                .priority(request.getPriority())
                .dueDate(request.getDueDate())
                .tags(request.getTags())
                .build();

        return taskRepository.save(task);
    }

    // Update task
    @Transactional
    public Task updateTask(String email, UUID taskId, TaskRequest request) {
        User user = getUserByEmail(email);

        Task task = taskRepository.findByIdAndUserId(taskId, user.getId())
                .orElseThrow(() -> new RuntimeException("Task not found"));

        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setStatus(request.getStatus());
        task.setPriority(request.getPriority());
        task.setDueDate(request.getDueDate());
        task.setTags(request.getTags());

        return taskRepository.save(task);
    }

    // Delete task
    @Transactional
    public void deleteTask(String email, UUID taskId) {
        User user = getUserByEmail(email);

        Task task = taskRepository.findByIdAndUserId(taskId, user.getId())
                .orElseThrow(() -> new RuntimeException("Task not found"));

        taskRepository.delete(task);
    }

    // Statistics
    public java.util.Map<String, Long> getTaskStats(String email) {
        User user = getUserByEmail(email);
        return java.util.Map.of(
                "todo",        taskRepository.countByUserIdAndStatus(user.getId(), "todo"),
                "in_progress", taskRepository.countByUserIdAndStatus(user.getId(), "in_progress"),
                "done",        taskRepository.countByUserIdAndStatus(user.getId(), "done")
        );
    }

    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found: " + email));
    }
}
