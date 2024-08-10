package com.cyrus822.ai_demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.ImageGenerationData;
import com.azure.ai.openai.models.ImageGenerationOptions;
import com.azure.ai.openai.models.ImageGenerations;
import com.azure.core.credential.AzureKeyCredential;

@Component
public class AIRunner implements CommandLineRunner {

    @Value("${openai.key}")
    private String key;

    @Value("${openai.endpoint}")
    private String endpoint;

    @Value("${openai.model}")
    private String model;

    @Override
    public void run(String... args) throws Exception {
        boolean canEnd = true;
        do {
            try {
                OpenAIClient client = new OpenAIClientBuilder().endpoint(endpoint)
                        .credential(new AzureKeyCredential(key)).buildClient();

                String prompt = "A cute cat writing Spring Boot Applicaton in Java";

                ImageGenerationOptions opts = new ImageGenerationOptions(prompt);
                ImageGenerations images = client.getImageGenerations(model, opts);

                for (ImageGenerationData imageGenerationData : images.getData()) {
                    System.out.printf(
                            "%nImage location URL that provides temporary access to download the generated image is %s",
                            imageGenerationData.getUrl());
                }
                canEnd = true;
            } catch (com.azure.core.exception.ResourceNotFoundException e) {
                canEnd = false;
                System.out.println("Model not ready, wait for 60 seconds");
                Thread.sleep(60 * 1000);
            } // end of try-catch
        } while (!canEnd);
    }

}