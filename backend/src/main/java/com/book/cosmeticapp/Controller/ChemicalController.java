package com.book.cosmeticapp.Controller;

import com.book.cosmeticapp.Model.Chemical;
import com.book.cosmeticapp.Service.ChemicalService;
import com.book.cosmeticapp.Service.DeepSeekService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/cosmetics")
public class ChemicalController {
    @Autowired
    private ChemicalService chemicalService;

    @Autowired
    private DeepSeekService deepSeekService;

    @PostMapping("/analyzeBatch")
    public ResponseEntity<?> analyzeBatch(@RequestBody List<String> chemicalNames) {
        List<Map<String, Object>> results = new ArrayList<>();

        for (String rawName : chemicalNames) {
            String name = rawName.trim().replaceAll("\\s+", " ");
            Optional<Chemical> optional = chemicalService.findByName(name);
            Map<String, Object> result = new HashMap<>();
            result.put("name", name);

            if (optional.isPresent()) {
                Chemical c = optional.get();
                result.put("chemical", c);
                result.put("message", c.isHarmful() ? "Harmful ingredient found" : "This ingredient is not harmful");
            } else {
                Chemical analyzed = deepSeekService.analyze(name);
                chemicalService.addChemical(analyzed);

                result.put("chemical", analyzed);
                result.put("message", analyzed.isHarmful()
                        ? "Harmful ingredient found (via AI analysis)"
                        : "This ingredient is not harmful (via AI analysis)");
            }

            results.add(result);

        }

        return ResponseEntity.ok(results);
    }

    @GetMapping("/search")
    public ResponseEntity<?> search(@RequestParam String name) {
        return chemicalService.findByName(name)
                .map(c -> {
                    if(c.isHarmful()){
                        return ResponseEntity.ok(c);
                    }else{
                        return ResponseEntity
                                .status(HttpStatus.OK)
                                .body(null);
                    }
                })
                .orElseGet(() -> {
                    Chemical response = deepSeekService.analyze(name);

                    if(!response.isHarmful()){
                        chemicalService.addChemical(response);

                        Map<String, Object> result = new HashMap<>();
                        result.put("chemical", response);
                        result.put("message", "This content does not contain harmful ingredients");
                        return ResponseEntity
                                .status(HttpStatus.OK)
                                .body(result);
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
    public ResponseEntity<Chemical> addChemical(@PathVariable Long id, @RequestBody Chemical chemical) {
        Chemical updatedChemical = chemicalService.updateChemical(id, chemical);
        return ResponseEntity.ok(updatedChemical);
    }
}
