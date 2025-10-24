package com.book.cosmeticapp.Model;

import jakarta.persistence.*;
import lombok.*;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Entity
@Table(name = "chemical")
@Getter
@Setter
public class Chemical {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String description;

    @Column(nullable=false)
    private boolean harmful;

    public Chemical(String name, String s, boolean b) {
        this.name= name;
        this.description =s ;
        this.harmful = b;
    }

    public boolean isHarmful() {
        return harmful;
    }
}
