@RestResource(urlMapping='/paymentwebhook/*')
global with sharing class AuthorizeNetPaymentWebhook {
    
    @httpPost
    global static void postPayment(){
        Restrequest req = RestContext.request; 
        system.debug('Body===>' + req.requestBody.toString());
        ManagePaymentService.processWebhook(req.requestBody.toString());
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = blob.valueOf('{"success":"true"}'); 

    }

}