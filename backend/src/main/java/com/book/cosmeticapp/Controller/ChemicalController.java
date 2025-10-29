package com.book.cosmeticapp.Controller;

import com.book.cosmeticapp.Model.Chemical;
import com.book.cosmeticapp.Service.ChemicalService;
import com.book.cosmeticapp.Service.DeepSeekService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/cosmetics")
public class ChemicalController {
    @Autowired
    private ChemicalService chemicalService;

    @Autowired
    private DeepSeekService deepSeekService;

    // 5 thread ile paralel işleme
    private final ExecutorService executorService = Executors.newFixedThreadPool(15);

    @GetMapping("/test")
    public ResponseEntity<?> testConnection() {
        try {
            long count = chemicalService.count(); // ChemicalService'e count metodu eklemeniz gerekecek
            return ResponseEntity.ok(Map.of(
                    "status", "OK",
                    "database", "connected",
                    "chemical_count", count
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                            "status", "ERROR",
                            "error", e.getMessage()
                    ));
        }
    }

    @PostMapping("/analyzeBatch")
    public ResponseEntity<?> analyzeBatch(@RequestBody List<String> chemicalNames) {
        long startTime = System.currentTimeMillis();

        System.out.println("========================================");
        System.out.println("📥 RECEIVED " + (chemicalNames != null ? chemicalNames.size() : 0) + " INGREDIENTS");
        System.out.println("========================================");

        try {
            if (chemicalNames == null || chemicalNames.isEmpty()) {
                System.out.println("❌ Empty ingredient list");
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Empty ingredient list"));
            }

            // İlk 20 içerikle sınırla (güvenlik için)
            List<String> limitedList = chemicalNames.size() > 20
                    ? chemicalNames.subList(0, 20)
                    : chemicalNames;

            if (chemicalNames.size() > 20) {
                System.out.println("⚠️ Limited to 20 ingredients (received " + chemicalNames.size() + ")");
            }

            System.out.println("🚀 Starting parallel processing...");

            // Paralel işleme
            List<CompletableFuture<Map<String, Object>>> futures = limitedList.stream()
                    .map(rawName -> CompletableFuture.supplyAsync(
                            () -> processIngredient(rawName),
                            executorService
                    ))
                    .collect(Collectors.toList());

            // Tüm sonuçları bekle
            List<Map<String, Object>> results = new ArrayList<>();
            for (CompletableFuture<Map<String, Object>> future : futures) {
                try {
                    results.add(future.get(60, TimeUnit.SECONDS));
                } catch (TimeoutException e) {
                    System.err.println("⏱️ Timeout for an ingredient");
                    Map<String, Object> errorResult = new HashMap<>();
                    errorResult.put("error", "Timeout");
                    results.add(errorResult);
                } catch (Exception e) {
                    System.err.println("❌ Processing error: " + e.getMessage());
                    Map<String, Object> errorResult = new HashMap<>();
                    errorResult.put("error", e.getMessage());
                    results.add(errorResult);
                }
            }

            long duration = System.currentTimeMillis() - startTime;
            System.out.println("========================================");
            System.out.println("✅ PROCESSED " + results.size() + " ingredients in " + duration + "ms (" + (duration/1000) + "s)");
            System.out.println("========================================");

            return ResponseEntity.ok(results);

        } catch (Exception ex) {
            System.err.println("💥 FATAL ERROR: " + ex.getMessage());
            ex.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Server error", "detail", ex.getMessage()));
        }
    }

    private Map<String, Object> processIngredient(String rawName) {
        long itemStart = System.currentTimeMillis();

        try {
            String name = rawName.trim().replaceAll("\\s+", " ");

            if (name.length() < 3) {
                System.out.println("⏭️ Skipped (too short): " + name);
                Map<String, Object> result = new HashMap<>();
                result.put("name", name);
                result.put("error", "Too short");
                return result;
            }

            Optional<Chemical> optional = chemicalService.findByName(name);
            Map<String, Object> result = new HashMap<>();
            result.put("name", name);

            if (optional.isPresent()) {
                // Veritabanında bulundu
                Chemical c = optional.get();
                result.put("chemical", c);
                result.put("message", c.isHarmful()
                        ? "Harmful ingredient found"
                        : "This ingredient is not harmful");

                long duration = System.currentTimeMillis() - itemStart;
                System.out.println("✓ DB: " + name + " (" + duration + "ms)");

            } else {
                // AI'a sor
                System.out.println("🤖 AI analyzing: " + name);
                Chemical analyzed = deepSeekService.analyze(name);
                chemicalService.addChemical(analyzed);

                result.put("chemical", analyzed);
                result.put("message", analyzed.isHarmful()
                        ? "Harmful ingredient found (via AI)"
                        : "Safe (via AI)");

                long duration = System.currentTimeMillis() - itemStart;
                System.out.println("✅ AI: " + name + " - " + (analyzed.isHarmful() ? "HARMFUL" : "SAFE") + " (" + duration + "ms)");
            }

            return result;

        } catch (Exception e) {
            long duration = System.currentTimeMillis() - itemStart;
            System.err.println("❌ ERROR: " + rawName + " - " + e.getMessage() + " (" + duration + "ms)");

            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("name", rawName);
            errorResult.put("error", "Failed: " + e.getMessage());
            return errorResult;
        }
    }

    @GetMapping("/search")
    public ResponseEntity<?> search(@RequestParam String name) {
        return chemicalService.findByName(name)
                .map(c -> {
                    if(c.isHarmful()){
                        return ResponseEntity.ok(c);
                    }else{
                        return ResponseEntity.status(HttpStatus.OK).body(null);
                    }
                })
                .orElseGet(() -> {
                    Chemical response = deepSeekService.analyze(name);
                    if(!response.isHarmful()){
                        chemicalService.addChemical(response);
                        Map<String, Object> result = new HashMap<>();
                        result.put("chemical", response);
                        result.put("message", "This content does not contain harmful ingredients");
                        return ResponseEntity.status(HttpStatus.OK).body(result);
                    }
                    chemicalService.addChemical(response);
                    return ResponseEntity.ok(response);
                });
    }

    @PostMapping("/add")
    public ResponseEntity<Chemical> addChemical(@RequestBody Chemical chemical) {
        return ResponseEntity.ok(chemicalService.addChemical(chemical));
    }

    @PostMapping("/update/{id}")
    public ResponseEntity<Chemical> updateChemical(@PathVariable Long id, @RequestBody Chemical chemical) {
        Chemical updatedChemical = chemicalService.updateChemical(id, chemical);
        return ResponseEntity.ok(updatedChemical);
    }
}