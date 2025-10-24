package com.book.cosmeticapp.Repository;

import com.book.cosmeticapp.Model.Chemical;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ChemicalRepository extends JpaRepository<Chemical, Long> {

    @Query("Select c From Chemical c where lower(c.name) = lower(:name)")
    Optional<Chemical> findByNameIgnoreCase(String name);
}