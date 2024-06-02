package com.cyrus822.demo.workload_identity.repos;

import org.springframework.data.jpa.repository.JpaRepository;
import com.cyrus822.demo.workload_identity.models.WiDemo;

public interface WiDemoRepo extends JpaRepository<WiDemo, Integer> {
    
}