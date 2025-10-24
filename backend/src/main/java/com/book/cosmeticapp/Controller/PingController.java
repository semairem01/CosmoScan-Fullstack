package com.book.cosmeticapp.Controller;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/cosmetics")
public class PingController {
    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }
}
