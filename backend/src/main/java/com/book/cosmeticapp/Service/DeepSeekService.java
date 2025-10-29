package com.book.cosmeticapp.Service;

import com.book.cosmeticapp.Model.Chemical;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DeepSeekService {

    @Value("${openai.api.key}")
    private String apiKey;

    private static final String OPENAI_URL = "https://api.openai.com/v1/chat/completions";
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();
    private static final int MAX_RETRIES = 2;

    public Chemical analyze(String name) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new RuntimeException("OpenAI API key is missing");
        }

        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                System.out.println("🤖 AI Request (attempt " + attempt + "): " + name);
                return performAnalysis(name);
            } catch (Exception e) {
                lastException = e;
                System.err.println("⚠️ Attempt " + attempt + " failed: " + e.getMessage());

                if (attempt < MAX_RETRIES) {
                    try {
                        Thread.sleep(1000 * attempt);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                    }
                }
            }
        }

        throw new RuntimeException("AI analysis failed after " + MAX_RETRIES + " attempts", lastException);
    }

    private Chemical performAnalysis(String name) {
        // 🔥 DAHA KISA VE NET PROMPT
        String prompt = String.format(
                "Ingredient: %s\nReturn JSON: {\"name\":\"string\",\"description\":\"max 100 chars\",\"harmful\":boolean}",
                name
        );

        Map<String, Object> userMsg = Map.of("role", "user", "content", prompt);

        Map<String, Object> body = new HashMap<>();
        body.put("model", "gpt-5-nano");
        body.put("messages", List.of(userMsg));

        // 🔥 DAHA YÜKSEK TOKEN LİMİTİ - reasoning model için gerekli
        body.put("max_completion_tokens", 2000); // 1000 → 2000


        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> resp = restTemplate.exchange(
                    OPENAI_URL,
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            if (!resp.getStatusCode().is2xxSuccessful() || resp.getBody() == null) {
                throw new RuntimeException("OpenAI API error: " + resp.getStatusCode());
            }

            List<Map<String, Object>> choices = (List<Map<String, Object>>) resp.getBody().get("choices");
            if (choices == null || choices.isEmpty()) {
                throw new RuntimeException("OpenAI returned empty choices");
            }

            Map<String, Object> firstChoice = choices.get(0);
            String finishReason = (String) firstChoice.get("finish_reason");

            Map<String, Object> messageObj = (Map<String, Object>) firstChoice.get("message");
            if (messageObj == null) {
                throw new RuntimeException("Message object is null");
            }

            String content = (String) messageObj.get("content");

            if (content == null || content.isBlank()) {
                throw new RuntimeException("Empty content. Finish reason: " + finishReason);
            }

            // JSON extract et - bazen ekstra text olabiliyor
            String cleaned = extractJson(content);

            System.out.println("✅ AI Response: " + cleaned);
            return mapper.readValue(cleaned, Chemical.class);

        } catch (HttpClientErrorException.Unauthorized e) {
            throw new RuntimeException("OpenAI 401: Invalid API key");
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new RuntimeException("OpenAI 429: Rate limit exceeded");
        } catch (HttpClientErrorException.BadRequest e) {
            // 400 hatalarını yakala
            String errorBody = e.getResponseBodyAsString();
            throw new RuntimeException("OpenAI 400: " + errorBody);
        } catch (Exception e) {
            throw new RuntimeException("OpenAI request failed: " + e.getMessage(), e);
        }
    }

    // JSON'u içerikten çıkar
    private String extractJson(String content) {
        // Markdown code blocks temizle
        String cleaned = content
                .replaceAll("(?s)```json\\s*", "")
                .replaceAll("(?s)```", "")
                .trim();

        // Eğer { ile başlamıyorsa, { karakterini bul
        if (!cleaned.startsWith("{")) {
            int startIdx = cleaned.indexOf("{");
            if (startIdx != -1) {
                cleaned = cleaned.substring(startIdx);
            }
        }

        // Eğer } ile bitmiyorsa, son } karakterini bul
        if (!cleaned.endsWith("}")) {
            int endIdx = cleaned.lastIndexOf("}");
            if (endIdx != -1) {
                cleaned = cleaned.substring(0, endIdx + 1);
            }
        }

        return cleaned;
    }
}