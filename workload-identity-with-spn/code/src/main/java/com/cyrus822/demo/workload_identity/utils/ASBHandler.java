package com.cyrus822.demo.workload_identity.utils;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import com.azure.core.credential.TokenCredential;
import com.azure.core.util.BinaryData;
import com.azure.identity.ClientSecretCredentialBuilder;
import com.azure.identity.WorkloadIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import static java.nio.charset.StandardCharsets.UTF_8;

@Component
public class ASBHandler {
    
    private static final Logger LOGGER = LoggerFactory.getLogger(ASBHandler.class);

    @Value("${spring.cloud.azure.servicebus.credential.client-id}")
    private String clientId;

    @Value("${spring.cloud.azure.servicebus.credential.client-secret}")
    private String clientSecret; 

    @Value("${spring.cloud.azure.servicebus.profile.tenant-id}")
    private String tenantId;         

    @Value("${spring.cloud.azure.servicebus.namespace}")
    private String namespace;

    @Value("${asb.entity.name}")
    private String topic; 

    @Value("${appConfig.asb.sleepTime}")
    private long sleepTime;

    @Value("${appConfig.auth}")
    private String authType;

    private TokenCredential credential;

    public String sendASBMsg(String msg){
        try{
            //Step-1 : prepare the TokenCredential
            if(authType.trim().equals("spn")){
                LOGGER.info("[Start::ASBHandler::run()::Step-1::prepare the TokenCredential]");  
                credential = new ClientSecretCredentialBuilder()
                                                .clientId(clientId)
                                                .clientSecret(clientSecret)
                                                .tenantId(tenantId)
                                                .build();                    
            } else {
                LOGGER.info("[Start::ASBHandler::run()::Step-1::prepare the WorkloadIdentityCredentialBuilder]");  
                credential = new WorkloadIdentityCredentialBuilder()
                                                .clientId(clientId)            
                                                .build();
            }
                                                  
            //Step-2 : prepare the ServiceBusSenderClient
            LOGGER.info("[Start::ASBHandler::run()::Step-2::prepare the ServiceBusSenderClient]");  
            ServiceBusSenderClient client = new ServiceBusClientBuilder()
                                            .credential(namespace, credential)
                                            .sender()
                                            .topicName(topic)
                                            .buildClient();

            //Step-3 : Format the string input
            LOGGER.info("[Start::ASBHandler::run()::Step-3::Format the string input]");
            String input = formatString(msg);

            //Step-4 : prepare the ServiceBusMessage
            LOGGER.info("[Start::ASBHandler::run()::Step-4::prepare the ServiceBusMessage]");   
            ServiceBusMessage asbMsg = new ServiceBusMessage(BinaryData.fromBytes(input.getBytes(UTF_8)));

            //Step-5 : send out the message
            LOGGER.info("[Start::ASBHandler::run()::Step-5::send out the message]");   
            client.sendMessage(asbMsg);

            //Step-6 : close the client
            LOGGER.info("[Start::ASBHandler::run()::Step-6::close the client]");    
            client.close();         
        }catch (Exception e){
            String errMsg = String.format("Error in ASBHandler::run()::", e.getMessage());
            LOGGER.error(errMsg, e);
            return errMsg;
        }
        return "Send success";
    }

    private String formatString(String msg){
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss");
        return String.format("%s sent at %s", msg, LocalDateTime.now().format(fmt));
    }        
}
