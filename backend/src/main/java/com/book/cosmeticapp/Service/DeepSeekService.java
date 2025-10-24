package com.book.cosmeticapp.Service;

import com.book.cosmeticapp.Model.Chemical;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DeepSeekService {

    @Value("${deepseek.api.key}")
    private String apiKey;

    private final String DEEPSEEK_URL = "https://openrouter.ai/api/v1/chat/completions";

    ResponseEntity<Map> response;
    public Chemical analyze(String name) {
        System.out.println("API Key "+ apiKey);
        RestTemplate restTemplate = new RestTemplate();

        Map<String, Object> message = new HashMap<>();
        message.put("role", "user");
        message.put("content", "Aşağıdaki içerik hakkında JSON formatında bir çıktı ver. Çıktı üç alandan oluşmalı:Harmful alanı için true ya da false yazılması yeterlidir. \"name\", \"description\", \"harmful\". İçerik: \"" + name + "\"");

        Map<String, Object> body = new HashMap<>();
        body.put("model", "deepseek/deepseek-r1:free");
        body.put("messages", List.of(message));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);
        headers.set("HTTP-Referer", "https://www.sitename.com");
        headers.set("X-Title", "SiteName");


        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            response = restTemplate.exchange(
                    DEEPSEEK_URL,
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
            if (choices != null && !choices.isEmpty()) {
                Map<String, Object> messageObj = (Map<String, Object>) choices.get(0).get("message");
                String content = (String) messageObj.get("content");

                //Read the content
                System.out.println("AI Response Content: " + content);


                // JSON yanıtı Chemical objesine çevir
                ObjectMapper mapper = new ObjectMapper();
                // Markdown bloklarını temizle
                String cleanedContent = content.replaceAll("(?s)```json\\s*", "") // baştaki ```json
                        .replaceAll("(?s)```", "")          // sondaki ```
                        .trim();
                return mapper.readValue(cleanedContent, Chemical.class);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }


        System.out.println("STATUS: " + response.getStatusCode());
        System.out.println("BODY: " + response.getBody());

        throw new RuntimeException("AI cevabı alınamadı.");
    }

}
