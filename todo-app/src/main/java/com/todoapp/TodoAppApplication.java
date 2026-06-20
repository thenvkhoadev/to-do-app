package com.todoapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class TodoAppApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoAppApplication.class, args);
    }
}
