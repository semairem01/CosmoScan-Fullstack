package com.book.cosmeticapp.Service;

import com.book.cosmeticapp.Model.Chemical;
import com.book.cosmeticapp.Repository.ChemicalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ChemicalService {
    @Autowired
    private ChemicalRepository chemicalRepository;

    public Optional<Chemical> findByName(String name){
        return chemicalRepository.findByNameIgnoreCase(name);
    }

    public Chemical addChemical(Chemical chemical){
        return chemicalRepository.save(chemical);
    }

    public Chemical findByID(Long id){
        return chemicalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Chemical not found with id: "+ id));
    }

    public Chemical updateChemical(Long id, Chemical chemical){
        Chemical chemicalToUpdate = findByID(id);

        chemicalToUpdate.setName(chemical.getName());
        chemicalToUpdate.setDescription(chemical.getDescription());
        chemicalToUpdate.setHarmful(chemical.isHarmful());

        return chemicalRepository.save(chemicalToUpdate);
    }
}
