package com.cyrus822.demo.workload_identity.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import com.cyrus822.demo.workload_identity.models.WiDemo;
import com.cyrus822.demo.workload_identity.repos.WiDemoRepo;
import com.cyrus822.demo.workload_identity.utils.ASBHandler;

@RestController
public class WIDemoController {

    @Autowired
    private ASBHandler asbHandler;

    @Autowired
    private WiDemoRepo repo;

    @GetMapping("/sendAsb/{msg}")
    public String sendAsb(@PathVariable("msg") String msg) {
        return asbHandler.sendASBMsg(msg);
    }

    @GetMapping("/saveToDB/{msg}")
    public String saveToDB(@PathVariable("msg") String msg) {
        try {
            repo.save(new WiDemo(0, msg));
        } catch (Exception e) {
            return String.format("Error in WIDemoController::saveToDB()::%s", e.getMessage());
        }
        return "Success save to DB";
    }

}