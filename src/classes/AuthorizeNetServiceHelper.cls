/**
 * This class is responsible to serve all the transactions realated to Authorize.NET. 
 * It implements the PaymentServiceInterface
 * 
 */
public with sharing class AuthorizeNetServiceHelper {

    public static Map<String, String> UNIT_MAPPING = new Map<String, String>{'Monthly'=>'months', 'Weekly'=>'days'};

    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper processChargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails, String company, Decimal amount, String apilogin, String authKey){

            Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
            ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
    
            System.debug('paymentDetails===>' + paymentDetails.serviceChargeTransaction);
            JSONGenerator gen = JSON.createGenerator(true);
    
            Boolean creditcard = true;
            if(paymentDetails.bankdetails.accountNumber != null){
                creditcard = false;
            }
            gen.writeStartObject();     
            gen.writeFieldName('createTransactionRequest');
            gen.writeStartObject();
                gen.writeFieldName('merchantAuthentication');
                    gen.writeStartObject();   
                    gen.writeStringField('name', apilogin);
                    gen.writeStringField('transactionKey', authKey);
                    gen.writeEndObject();
                gen.writeStringField('refId', paymentDetails.otherdetails.refId);
                gen.writeFieldName('transactionRequest');
                gen.writeStartObject();
                gen.writeStringField('transactionType', 'authCaptureTransaction');
                gen.writeStringField('amount', String.valueOf(amount));
                gen.writeFieldName('payment');
                    gen.writeStartObject();
                        if(creditcard){
                        gen.writeFieldName('creditCard');
                            gen.writeStartObject();
                            gen.writeStringField('cardNumber', paymentDetails.carddetails.cardNumber.replaceAll(' ', ''));
                            gen.writeStringField('expirationDate', '20'+ paymentDetails.carddetails.cardExpiry.split('/')[1].trim() + '-' + paymentDetails.carddetails.cardExpiry.split('/')[0].trim());
                            gen.writeStringField('cardCode', paymentDetails.carddetails.cardCVV);
                            gen.writeEndObject();
                        }else{
                            gen.writeFieldName('bankAccount');
                            gen.writeStartObject();
                            gen.writeStringField('accountType', paymentDetails.bankdetails.accountType);
                            gen.writeStringField('routingNumber', paymentDetails.bankdetails.routingNumber.replaceAll(' ', ''));
                            gen.writeStringField('accountNumber', paymentDetails.bankdetails.accountNumber.replaceAll(' ', ''));
                            gen.writeStringField('nameOnAccount', paymentDetails.bankdetails.nameOnAccount);
                            gen.writeEndObject();
    
                        }
                    gen.writeEndObject();
                gen.writeFieldName('customer');
                    gen.writeStartObject();
                        gen.writeStringField('id', (paymentDetails.serviceChargeTransaction ? paymentDetails.otherdetails.refId :  paymentDetails.otherdetails.refId));
                    gen.writeEndObject();
    
                gen.writeFieldName('billTo');
                    gen.writeStartObject();
                    if(creditCard){
                        gen.writeStringField('firstName', paymentDetails.carddetails.cardHolderFirstName);
                        gen.writeStringField('lastName', paymentDetails.carddetails.cardHolderLastName);
                    }else{
                        gen.writeStringField('firstName', paymentDetails.bankdetails.nameOnAccount);
                        gen.writeStringField('lastName', paymentDetails.bankdetails.nameOnAccount);
                    }
                        gen.writeStringField('company', paymentDetails.otherDetails.company == null ? '' : paymentDetails.otherDetails.company);
                        gen.writeStringField('address', paymentDetails.addressdetails.BillingStreet);
                        gen.writeStringField('city', paymentDetails.addressdetails.BillingCity);
                        gen.writeStringField('state', paymentDetails.addressdetails.BillingState);
                        gen.writeStringField('zip', paymentDetails.addressdetails.BillingPostalCode);
                        gen.writeStringField('country', paymentDetails.addressdetails.BillingCountry);
                
                    gen.writeEndObject();
    
                    gen.writeFieldName('shipTo');
                    gen.writeStartObject();
                    if(creditCard){
    
                        gen.writeStringField('firstName', paymentDetails.carddetails.cardHolderFirstName);
                        gen.writeStringField('lastName', paymentDetails.carddetails.cardHolderLastName);
                    }
                    gen.writeStringField('company', company);
                    gen.writeStringField('address', paymentDetails.addressdetails.BillingStreet);
                    gen.writeStringField('city', paymentDetails.addressdetails.BillingCity);
                    gen.writeStringField('state', paymentDetails.addressdetails.BillingState);
                    gen.writeStringField('zip', paymentDetails.addressdetails.BillingPostalCode);
                    gen.writeStringField('country', paymentDetails.addressdetails.BillingCountry);
    
                    gen.writeEndObject();
                    gen.writeEndObject();
    
                    gen.writeEndObject();
            gen.writeEndObject();
    
            String jsonData = gen.getAsString();
    
            System.debug('MyData===>' + jsonData);
    
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
            req.setMethod('POST');
            req.setBody(jsonData);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept','application/json');
    
            System.debug('JSON Request :: ' + Json.serialize(jsonData));
            HttpResponse res = http.send(req);
            System.debug('JSON Response :: ' + res.getBody());
    
            ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper rw = (ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper.class);
            trw.requestString = jsonData;
            trw.responseString = res.getBody();
            trw.statuscode = res.getStatusCode();
            String responseMessage = '';
    
            if(rw.messages != null && !rw.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : rw.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }
    
            if(rw.transactionResponse != null && rw.transactionResponse.messages != null && !rw.transactionResponse.messages.isempty()){
                for(ManagePaymentDTOService.Transaction_response_messages message : rw.transactionResponse.messages){
                    responseMessage += 'Success Code = ' + message.code + ' :: Description = ' + message.description + ' \n';
                }
            }
            responseMessage += '\n';
    
            if(rw.transactionResponse != null && rw.transactionResponse.errors != null&& !rw.transactionResponse.errors.isempty()){
                for(ManagePaymentDTOService.cls_error message : rw.transactionResponse.errors){
                    responseMessage += 'Code :: ' + message.errorCode + ' :: Description = ' + message.errorText + '\n';
                }
            }
            if(rw.messages.resultCode == 'Ok' && (rw.transactionResponse.errors == null || rw.transactionResponse.errors.isempty())){
                trw.statuscode = 200;
                trw.transId = rw.transactionResponse.transId;
                trw.authCode = rw.transactionResponse.authCode;
                trw.accountNumber = rw.transactionResponse.accountNumber;
                trw.accountType = rw.transactionResponse.accountType;
                trw.resultCode = rw.messages.resultCode;
                trw.issuccess = true;
            }else{
                trw.issuccess = false;
            }
            trw.responseMessage = responseMessage;
            return trw;
    
    }

    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper processRefundTransaction(PaymentDataWrapper pdw){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(pdw.paymentObj.SObect_API_Name__c, pdw.paymentObj.Source__c);

            List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

            JSONGenerator gen = JSON.createGenerator(true);

            Boolean creditcard = true;
            if(pdw.paymentObj.Card_Type__c == 'eCheck'){
                creditcard = false;
            }
            gen.writeStartObject();
            gen.writeFieldName('createTransactionRequest');
            gen.writeStartObject();
                gen.writeFieldName('merchantAuthentication');
                    gen.writeStartObject();    
                    gen.writeStringField('name', pdw.apilogin);
                    gen.writeStringField('transactionKey', pdw.authKey);
                    gen.writeEndObject();
                gen.writeStringField('refTransId', pdw.transactionId);
                gen.writeFieldName('transactionRequest');
                gen.writeStartObject();
                gen.writeStringField('transactionType', 'refundTransaction');
                gen.writeStringField('amount', String.valueOf(pdw.amount));//paymentObj.Card_Services_Fee__c));
                gen.writeFieldName('payment');
                    gen.writeStartObject();
                        if(creditcard){
                        gen.writeFieldName('creditCard');
                            gen.writeStartObject();
                            gen.writeStringField('cardNumber', pdw.paymentObj.Card_Number__c);
                            gen.writeStringField('expirationDate', 'XXXX');
                            gen.writeEndObject();
                        }else{
                            gen.writeFieldName('bankAccount');
                            gen.writeStartObject();
                            gen.writeStringField('accountType', pdw.paymentObj.Account_Type__c);
                            gen.writeStringField('routingNumber', pdw.paymentObj.Routing_Number__c);
                            gen.writeStringField('accountNumber', pdw.paymentObj.Account_Number__c);
                            gen.writeStringField('nameOnAccount', pdw.paymentObj.Name_on_Account__c);
                            gen.writeEndObject();
                        }
                    gen.writeEndObject();
                    //gen.writeStringField('refTransId', transactionId);
                
                    gen.writeEndObject();

                    gen.writeEndObject();
            gen.writeEndObject();

            String json = gen.getAsString();

            System.debug('MyData===>' + json);


            Http http = new Http();

            HttpRequest req = new HttpRequest();
            req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
            req.setMethod('POST');
            req.setBody(json);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept','application/json');

            HttpResponse res = http.send(req);
            String response = res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿','');
            System.debug('res==>' + response);

            //return (ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper) System.JSON.deserialize(response, ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper.class);

            ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper values = (ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper.class);
            ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
            trw.requestString = json;
            trw.responseString = res.getBody();
            trw.statuscode = res.getStatusCode();

            String responseMessage = '';

            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }

            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();

            if(values.transactionResponse != null && values.transactionResponse.messages != null && !values.transactionResponse.messages.isempty()){
                for(ManagePaymentDTOService.Transaction_response_messages message : values.transactionResponse.messages){
                    responseMessage += 'Success Code = ' + message.code + ' :: Description = ' + message.description + ' \n';
                }
            }
            responseMessage += '\n';

            if(values.transactionResponse != null && values.transactionResponse.errors != null&& !values.transactionResponse.errors.isempty()){
                for(ManagePaymentDTOService.cls_error message : values.transactionResponse.errors){
                    responseMessage += 'Code :: ' + message.errorCode + ' :: Description = ' + message.errorText + '\n';
                }
            }

            if(values.messages.resultCode == 'Ok' && (values.transactionResponse.errors == null || values.transactionResponse.errors.isempty())){
                trw.issuccess = true;
                trw.authCode = values.transactionResponse.authCode;
                trw.transId = values.transactionResponse.transId;
                trw.accountNumber = values.transactionResponse.accountNumber;
                trw.accountType = values.transactionResponse.accountType;
                trw.resultCode = values.messages.resultCode;
            }else{
                trw.issuccess = false;
            }
            trw.responseMessage = responseMessage;
            return trw;

    }

    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper processVoidTransaction(PaymentDataWrapper pdw){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(pdw.paymentObj.SObect_API_Name__c, pdw.paymentObj.Source__c);
        system.debug('pconfig=====>'+ pconfig);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();     
        gen.writeFieldName('createTransactionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();   
                gen.writeStringField('name', pdw.apilogin);
                gen.writeStringField('transactionKey', pdw.authKey);
            gen.writeEndObject();
            gen.writeFieldName('transactionRequest');
            gen.writeStartObject();   
            gen.writeStringField('transactionType', 'voidTransaction');
            gen.writeStringField('refTransId', pdw.transactionId);
            
                gen.writeEndObject();

                gen.writeEndObject();
        gen.writeEndObject();

        String json = gen.getAsString();

        System.debug('MyData===>' + json);

        Http http = new Http();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(json);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');

        HttpResponse res = http.send(req);
        String response = res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿','');
        System.debug('res==>' + response);

        ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper values = (ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Auth_Transaction_Reponse_Wrapper.class);
        ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
        trw.requestString = json;
        trw.responseString = res.getBody();
        trw.statuscode = res.getStatusCode();
        String responseMessage = '';
        trw.issuccess = false;
        if(values.transactionResponse.messages != null && !values.transactionResponse.messages.isempty()){
            for(ManagePaymentDTOService.Transaction_response_messages message : values.transactionResponse.messages){
                if(message.code == '1'){
                    trw.issuccess = true;
                }else{
                    trw.issuccess = false;
                }
                responseMessage += 'Code = ' + message.code + (message.description != null ? ' :: Description = ' + message.description : '') + ' \n';
            }
        }

        if(values.transactionResponse != null && values.transactionResponse.errors != null&& !values.transactionResponse.errors.isempty()){
            for(ManagePaymentDTOService.cls_error message : values.transactionResponse.errors){
                responseMessage += 'Code :: ' + message.errorCode + ' :: Description = ' + message.errorText + '\n';
            }
        }
        
            if(trw.issuccess){
                trw.issuccess = true;
                trw.authCode = values.transactionResponse.authCode;
                trw.transId = values.transactionResponse.transId;
                trw.accountNumber = values.transactionResponse.accountNumber;
                trw.accountType = values.transactionResponse.accountType;
                trw.resultCode = values.messages.resultCode;
                
            }else{
                trw.issuccess = false;

            }
            trw.responseMessage = responseMessage;
            return trw;
    }

    /**
     * This method is reponsible to create a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.Sub_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper processSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails, String company, Decimal amount, String apilogin, String authKey){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        System.debug('paymentDetails===>' + paymentDetails);
        JSONGenerator gen = JSON.createGenerator(true);

        Boolean creditcard = true;
        if(paymentDetails.bankdetails.accountNumber != null){
            creditcard = false;
        }
        gen.writeStartObject();     
        gen.writeFieldName('ARBCreateSubscriptionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();
                gen.writeStringField('name', apilogin);
                gen.writeStringField('transactionKey', authKey);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeFieldName('subscription');
            gen.writeStartObject();   
            gen.writeStringField('name', paymentDetails.subdetails.subname);

            gen.writeFieldName('paymentSchedule');
            gen.writeStartObject();
            gen.writeFieldName('interval');

                gen.writeStartObject();
                    gen.writeStringField('length', paymentDetails.subdetails.unit == 'Monthly' ? '1' : (paymentDetails.subdetails.unit == 'Weekly' ? '7' : ''));
                    gen.writeStringField('unit', UNIT_MAPPING.get(paymentDetails.subdetails.unit));
                gen.writeEndObject();
                gen.writeStringField('startDate', paymentDetails.subDetails.startDate);
                gen.writeStringField('totalOccurrences', paymentDetails.subDetails.occurrances);
            gen.writeEndObject();

            gen.writeStringField('amount', String.valueOf(amount));

            gen.writeFieldName('payment');
                gen.writeStartObject();
                    if(creditcard){
                    gen.writeFieldName('creditCard');
                        gen.writeStartObject();
                        gen.writeStringField('cardNumber', paymentDetails.carddetails.cardNumber.replaceAll(' ',''));
                        gen.writeStringField('expirationDate', '20'+ paymentDetails.carddetails.cardExpiry.split('/')[1].trim() + '-' + paymentDetails.carddetails.cardExpiry.split('/')[0].trim());
                        gen.writeStringField('cardCode', paymentDetails.carddetails.cardCVV);
                        gen.writeEndObject();
                    }else{
                        gen.writeFieldName('bankAccount');
                        gen.writeStartObject();
                        gen.writeStringField('accountType', paymentDetails.bankdetails.accountType);
                        gen.writeStringField('routingNumber', paymentDetails.bankdetails.routingNumber);
                        gen.writeStringField('accountNumber', paymentDetails.bankdetails.accountNumber);
                        gen.writeStringField('nameOnAccount', paymentDetails.bankdetails.nameOnAccount);
                        gen.writeEndObject();

                    }
                gen.writeEndObject();

                gen.writeFieldName('customer');
                gen.writeStartObject();
                    gen.writeStringField('type', 'individual');
                    gen.writeStringField('id', paymentDetails.otherdetails.refId);
            
                gen.writeEndObject();



            gen.writeFieldName('billTo');
                gen.writeStartObject();
                if(creditCard){
                    gen.writeStringField('firstName', paymentDetails.carddetails.cardHolderFirstName);
                    gen.writeStringField('lastName', paymentDetails.carddetails.cardHolderLastName);
                }else{
                    gen.writeStringField('firstName', paymentDetails.bankdetails.nameOnAccount);
                    gen.writeStringField('lastName', paymentDetails.bankdetails.nameOnAccount);
                }

            
                gen.writeEndObject();

                gen.writeEndObject();

                gen.writeEndObject();
        gen.writeEndObject();

        String jsonData = gen.getAsString();

        System.debug('MyData===>' + jsonData);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(jsonData);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');

        System.debug('JSON Request :: ' + Json.serialize(jsonData));
        HttpResponse res = http.send(req);
        System.debug('JSON Response :: ' + res.getBody());

        ManagePaymentDTOService.Sub_Reponse_Wrapper rw = (ManagePaymentDTOService.Sub_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Sub_Reponse_Wrapper.class);
        rw.requestString = jsonData;
        rw.responseString = res.getBody();
        rw.statuscode = res.getStatusCode();
        String responseMessage = '';

        if(rw.messages != null && !rw.messages.message.isempty()){
            for(ManagePaymentDTOService.cls_message message : rw.messages.message){
                responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
            }
        }

        if(rw.messages.resultCode == 'Ok' && rw.messages.message[0].code == 'I00001'){
            rw.issuccess = true;
        }else{
            rw.issuccess = false;
        }
        rw.responseString = responseMessage;

        return rw;
        
    }

    /**
     * This method is reponsible to update a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.PaymentDetails : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper processUpdateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails, String apilogin, String authKey, String subId){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);


        System.debug('paymentDetails===>' + paymentDetails);
        JSONGenerator gen = JSON.createGenerator(true);

        Boolean creditcard = true;
        if(paymentDetails.bankdetails.accountNumber != null){
            creditcard = false;
        }
        gen.writeStartObject();     
        gen.writeFieldName('ARBUpdateSubscriptionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();   
                gen.writeStringField('name', apilogin);
                gen.writeStringField('transactionKey', authKey);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeStringField('subscriptionId', subId);
            
            gen.writeFieldName('subscription');
            gen.writeStartObject();   

            gen.writeFieldName('payment');
                gen.writeStartObject();
                    if(creditcard){
                    gen.writeFieldName('creditCard');
                        gen.writeStartObject();
                        gen.writeStringField('cardNumber', paymentDetails.carddetails.cardNumber.replaceAll(' ',''));
                        gen.writeStringField('expirationDate', '20'+ paymentDetails.carddetails.cardExpiry.split('/')[1].trim() + '-' + paymentDetails.carddetails.cardExpiry.split('/')[0].trim());
                        gen.writeStringField('cardCode', paymentDetails.carddetails.cardCVV);
                        gen.writeEndObject();
                    }else{
                        gen.writeFieldName('bankAccount');
                        gen.writeStartObject();
                        gen.writeStringField('accountType', paymentDetails.bankdetails.accountType);
                        gen.writeStringField('routingNumber', paymentDetails.bankdetails.routingNumber);
                        gen.writeStringField('accountNumber', paymentDetails.bankdetails.accountNumber);
                        gen.writeStringField('nameOnAccount', paymentDetails.bankdetails.nameOnAccount);
                        gen.writeEndObject();

                    }
                gen.writeEndObject();

                gen.writeEndObject();

                gen.writeEndObject();
        gen.writeEndObject();

        String jsonData = gen.getAsString();

        System.debug('MyData===>' + jsonData);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(jsonData);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');

        System.debug('JSON Request :: ' + Json.serialize(jsonData));
        HttpResponse res = http.send(req);
        System.debug('JSON Response :: ' + res.getBody());

        //return (ManagePaymentDTOService.Sub_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Sub_Reponse_Wrapper.class);
        ManagePaymentDTOService.Sub_Reponse_Wrapper rw = (ManagePaymentDTOService.Sub_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Sub_Reponse_Wrapper.class);
        rw.requestString = jsonData;
        rw.responseString = res.getBody();
        rw.statuscode = res.getStatusCode();

        String responseMessage = '';

        if(rw.messages != null && !rw.messages.message.isempty()){
            for(ManagePaymentDTOService.cls_message message : rw.messages.message){
                responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
            }
        }
        System.debug('responseMessage>>>>>>>' + responseMessage);

        if(rw.messages.resultCode == 'Ok' && rw.messages.message[0].code == 'I00001'){
            rw.issuccess = true;
        }else{
            rw.issuccess = false;
            rw.responseMessage = responseMessage;
        }
        return rw;

    }

    /**
     * This method is reponsible to cancel a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.SubscriptionWrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper processCancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails, String apilogin, String authKey, String subId){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        System.debug('paymentDetails===>' + paymentDetails);
        Decimal amount = paymentDetails.otherdetails.amount;
        JSONGenerator gen = JSON.createGenerator(true);

        Boolean creditcard = true;
        if(paymentDetails.bankdetails.accountNumber != null){
            creditcard = false;
        }
        gen.writeStartObject();
        gen.writeFieldName('ARBCancelSubscriptionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();   
                gen.writeStringField('name', apilogin);
                gen.writeStringField('transactionKey', authKey);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeStringField('subscriptionId', subId);
            gen.writeEndObject();
        gen.writeEndObject();

        String jsonData = gen.getAsString();

        System.debug('MyData===>' + jsonData);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(jsonData);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');

        System.debug('JSON Request :: ' + Json.serialize(jsonData));
        HttpResponse res = http.send(req);
        System.debug('JSON Response :: ' + res.getBody());

       //return (ManagePaymentDTOService.SubscriptionWrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.SubscriptionWrapper.class);
        ManagePaymentDTOService.SubscriptionWrapper rw1 = (ManagePaymentDTOService.SubscriptionWrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.SubscriptionWrapper.class);
        ManagePaymentDTOService.Sub_Reponse_Wrapper srw = new ManagePaymentDTOService.Sub_Reponse_Wrapper();
        srw.requestString = jsonData;
        srw.responseString = res.getBody();
        srw.statuscode = res.getStatusCode();
        String responseMessage = '';

        if(rw1.messages != null && !rw1.messages.message.isempty()){
            for(ManagePaymentDTOService.cls_message message : rw1.messages.message){
                responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
            }
        }

        if(rw1.messages.resultCode == 'Ok' && rw1.messages.message[0].code == 'I00001'){
            srw.issuccess = true;
        }else{
            srw.issuccess = false;
            srw.responseMessage = responseMessage;
        }

        return srw;

    }

    public class PaymentDataWrapper{

        public Payment__c paymentObj;
        public String company;
        public Decimal amount; 
        public String apilogin;
        public String authKey;
        public String transactionId;
        public PaymentDataWrapper(Payment__c paymentObj, String company, Decimal amount, String apilogin, String authKey, String transactionId){
            this.paymentObj = paymentObj;
            this.company = company;
            this.amount = amount;
            this.apilogin = apilogin;
            this.authKey = authKey;
            this.transactionId = transactionId;
        }
    }

    // Payment Exceptions
    public class PaymentException extends Exception{}

}