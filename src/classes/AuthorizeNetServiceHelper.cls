public without sharing class AuthorizeNetServiceHelper implements PaymentServiceInterface{

    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper chargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails){
        //Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(ManagePaymentServiceHelper, paymentDetails.otherdetails.paymentserviceprovider);
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();

        System.debug('paymentDetails===>' + paymentDetails);
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
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeFieldName('transactionRequest');
            gen.writeStartObject();   
            gen.writeStringField('transactionType', 'authCaptureTransaction');
            gen.writeStringField('amount', String.valueOf(paymentDetails.otherdetails.amount));
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
                    gen.writeStringField('company', pconfig.Auth_API_Login_Id__c);
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
                gen.writeStringField('company', pconfig.Auth_API_Login_Id__c);
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
        ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
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


    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper refundTransaction(Payment__c paymentObj ){
        //Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentObj.SObect_API_Name__c, paymentObj.Source__c);

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentObj.SObect_API_Name__c, paymentObj.Source__c);

        JSONGenerator gen = JSON.createGenerator(true);

        Boolean creditcard = true;
        if(paymentObj.Card_Type__c == 'eCheck'){
            creditcard = false;
        }
        gen.writeStartObject();     
        gen.writeFieldName('createTransactionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();   
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
                gen.writeEndObject();
            //gen.writeStringField('refTransId', paymentObj.Transaction_Id__c);
            gen.writeFieldName('transactionRequest');
            gen.writeStartObject();   
            gen.writeStringField('transactionType', 'refundTransaction');
            gen.writeStringField('amount', String.valueOf(paymentObj.Amount__c));
            gen.writeFieldName('payment');
                gen.writeStartObject();
                    if(creditcard){
                    gen.writeFieldName('creditCard');
                        gen.writeStartObject();
                        gen.writeStringField('cardNumber', paymentObj.Card_Number__c);
                        gen.writeStringField('expirationDate', 'XXXX');
                        gen.writeEndObject();
                    }else{
                        gen.writeFieldName('bankAccount');
                        gen.writeStartObject();
                        gen.writeStringField('accountType', paymentObj.Account_Type__c);
                        gen.writeStringField('routingNumber', paymentObj.Routing_Number__c);
                        gen.writeStringField('accountNumber', paymentObj.Account_Number__c);
                        gen.writeStringField('nameOnAccount', paymentObj.Name_on_Account__c);
                        gen.writeEndObject();
                    }
                gen.writeEndObject();
                if(paymentObj.Transaction_Id__c != null)
                gen.writeStringField('refTransId', paymentObj.Transaction_Id__c);
            
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

    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper voidTransaction(Payment__c paymentObj){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentObj.SObect_API_Name__c, paymentObj.Source__c);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();     
        gen.writeFieldName('createTransactionRequest');
        gen.writeStartObject();
            gen.writeFieldName('merchantAuthentication');
                gen.writeStartObject();   
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
                gen.writeEndObject();
            //gen.writeStringField('refTransId', paymentObj.Transaction_Id__c);
            gen.writeFieldName('transactionRequest');
            gen.writeStartObject();   
            gen.writeStringField('transactionType', 'voidTransaction');
            gen.writeStringField('refTransId', paymentObj.Transaction_Id__c);
            
                
            
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
    public static Map<String, String> UNIT_MAPPING = new Map<String, String>{'Monthly'=>'months', 'Weekly'=>'days'};

    public static ManagePaymentDTOService.Sub_Reponse_Wrapper createSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails ){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        System.debug('paymentDetails===>' + paymentDetails);
        Decimal amount = paymentDetails.otherdetails.amount;
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
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
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

            gen.writeStringField('amount', String.valueOf(paymentDetails.subDetails.amount));

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
        return rw;
        
       // return (ManagePaymentDTOService.Sub_Reponse_Wrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Sub_Reponse_Wrapper.class);

    }

    public static ManagePaymentDTOService.Sub_Reponse_Wrapper updateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);


        System.debug('paymentDetails===>' + paymentDetails);
        Decimal amount = paymentDetails.otherdetails.amount;
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
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeStringField('subscriptionId', paymentDetails.otherdetails.subscriptionId);
            
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
        return rw;

    }


    public static ManagePaymentDTOService.SubscriptionWrapper cancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
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
                gen.writeStringField('name', pconfig.Auth_API_Login_Id__c);
                gen.writeStringField('transactionKey', pconfig.Auth_Transaction_Key__c);
                gen.writeEndObject();
            gen.writeStringField('refId', paymentDetails.otherdetails.refId);
            gen.writeStringField('subscriptionId', paymentDetails.otherdetails.subscriptionId);


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
        ManagePaymentDTOService.SubscriptionWrapper rw = (ManagePaymentDTOService.SubscriptionWrapper) System.JSON.deserialize(res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.SubscriptionWrapper.class);
        rw.requestString = jsonData;
        rw.responseString = res.getBody();
        rw.statuscode = res.getStatusCode();
        return rw;

    }

    public static ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(ManagePaymentDTOService.PaymentDetails paymentDetails){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        String query = 'select Amount__c,Card_Number__c,CreatedById,CreatedDate,Customer_Payment_ProfileId__c,Customer_Profile_Id__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Length__c,Name,Occurrances__c,Opportunity__c,OwnerId,Record_Id__c,Start_Date__c,Status__c,Subscription_Id__c,SystemModstamp,Unit__c from Subscription__c where '+paymentDetails.otherdetails.fieldapiname + '=\''+paymentDetails.otherdetails.refId+'\' and status__c = \'Active\'';
        List<Subscription__c> subscriptionList = Database.query(query);
        ManagePaymentDTOService.SubscriptionWrapper wrapper = new ManagePaymentDTOService.SubscriptionWrapper();
        wrapper.totalNumInResultSet = subscriptionList.size();
        wrapper.refId = paymentDetails.otherdetails.refId;
        
        List<ManagePaymentDTOService.cls_subscriptionDetails> subscriptionDetails = new List<ManagePaymentDTOService.cls_subscriptionDetails>();
        for(Subscription__c sub : subscriptionList){
            ManagePaymentDTOService.cls_subscriptionDetails sd = new ManagePaymentDTOService.cls_subscriptionDetails();
            sd.id = Integer.valueOf(sub.Subscription_Id__c);
            sd.name = sub.Name;
            sd.status = sub.status__c;
            sd.createTimeStampUTC = String.valueOf(sub.createddate);
            sd.totalOccurrences = Integer.valueOf(sub.Occurrances__c);
            sd.accountNumber = sub.Card_Number__c;
            sd.amount = sub.Amount__c;
            subscriptionDetails.add(sd);
        }
        wrapper.subscriptionDetails = subscriptionDetails;
        return wrapper;

    }

    public static void authorizeNetProcessWebhook(String requestbody){  
        API_Tracker__c at = new API_Tracker__c();
        at.Response_Body__c = requestbody;
        //Payment_Config__mdt pconfig = [select API_Login_Id__c, Track_Callback_Response__c,  Endpoint_URL__c, Transaction_Key__c, Return_URL__c from Payment_Config__mdt where developername = 'Authorize_Net_Config'];
        Payment_Configuration__c pconfig;

        List<Payment_Configuration__c> pconfiglist = [select External_Payment_URL__c, Community_URL__c, Enable_Logging__c, Auth_API_Login_Id__c, Endpoint_URL__c, Auth_Transaction_Key__c, 
        SObject_Payment_Lookup_API_Name__c, Object_Api_Name__c, Address_API_Name__c, Amount_API_Name__c,
        City_API_Name__c,Company_API_Name__c, Country_API_Name__c, Customer_Id_API_Name__c, Email_API_Name__c,First_Name_API_Name__c, Last_Name_API_Name__c,
            Product_API_Name__c, RefId_Api_Name__c, Return_URL__c,Return_URL_API_Name__c, State_API_Name__c, Zip_API_Name__c from Payment_Configuration__c where name = 'Authorize.Net'];
        if(pconfiglist != null && pconfiglist.size() > 0){
            pconfig = pconfiglist[0];
        }
        try{
            ManagePaymentDTOService.Notification values = (ManagePaymentDTOService.Notification) System.JSON.deserialize(requestbody.replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Notification.class);

        Http http = new Http();
        String json=		'{'+
        '    "getTransactionDetailsRequest": {'+
        '        "merchantAuthentication": {'+
        '            "name": "'+pconfig.Auth_API_Login_Id__c+'",'+
        '            "transactionKey": "'+ pconfig.Auth_Transaction_Key__c+'"'+
        '        },'+
        '        "transId": "'+values.payload.id+'"'+
        '    }'+
        '}';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(pconfig.Endpoint_URL__c + '/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(json);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');

        HttpResponse res = http.send(req);
        
        json = res.getBody().replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿','').replaceAll('"transaction"', '"transaction1"');
        System.debug('json====>' + json);
        at.put('Transaction_Detail_Response__c', json);

            //at.Callback_Response_JSON__c = res.getBody();
        System.debug('res==>' + res.getBody());

        ManagePaymentDTOService.cls_getTransactionDetailsResponse tdresp = (ManagePaymentDTOService.cls_getTransactionDetailsResponse) System.JSON.deserialize(json.replaceAll('"transaction"', '"transaction1"'), ManagePaymentDTOService.cls_getTransactionDetailsResponse.class);
        
        if(tdresp.transaction1 != null && tdresp.transaction1.subscription != null && tdresp.transaction1.subscription.id != null){
            Payment__c paymentObj = new Payment__c();
            paymentObj.Amount__c = values.payload.authAmount;
            paymentObj.Event_Type__c = values.eventType;
            
            paymentObj.Transaction_Id__c = values.payload.Id;
            paymentObj.Subscription__r = new Subscription__c(Subscription_Id__c = tdresp.transaction1.subscription.id);
            paymentObj.Payment_Number__c = tdresp.transaction1.subscription.payNum;
            
            paymentObj.Source__c = 'Authorize.Net';
            paymentObj.Payment_Date__c = System.today();

            if(tdresp.transaction1.customer != null){
                paymentObj.Customer_Id__c = tdresp.transaction1.customer.id;
            }
            paymentObj.Card_Type__c = tdresp.transaction1.payment.creditCard.cardType;
            paymentObj.Card_Number__c = tdresp.transaction1.payment.creditCard.cardNumber;
            paymentObj.Transaction_Status__c = tdresp.transaction1.transactionStatus;
            paymentObj.RecordtypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Subscription Payment').getRecordTypeId();

            if(tdresp.transaction1.shipTo != null){
                paymentObj.Ship_To_Address__c = tdresp.transaction1.shipTo.address;
                paymentObj.Ship_To_City__c = tdresp.transaction1.shipTo.address;
                paymentObj.Ship_To_State__c = tdresp.transaction1.shipTo.address;
                paymentObj.Ship_To_Zip__c = tdresp.transaction1.shipTo.address;
                paymentObj.Ship_To_Country__c = tdresp.transaction1.shipTo.country;
            }

            if(tdresp.transaction1.billTo != null){
                paymentObj.Bill_To_Address__c = tdresp.transaction1.billTo.address;
                paymentObj.Bill_To_City__c = tdresp.transaction1.billTo.city;
                paymentObj.Bill_To_State__c = tdresp.transaction1.billTo.state;
                paymentObj.Bill_To_Zip__c = tdresp.transaction1.billTo.zip;
                paymentObj.Bill_To_Country__c = tdresp.transaction1.billTo.country;
                paymentObj.Bill_To_Phone__c = tdresp.transaction1.billTo.phoneNumber;
                paymentObj.Bill_To_First_Name__c = tdresp.transaction1.billTo.firstName;
                paymentObj.Bill_To_Last_Name__c = tdresp.transaction1.billTo.lastName;      
            }

            if(tdresp.messages.resultCode == 'Ok' && tdresp.messages.message[0].code == 'I00001'){
                paymentObj.Status_Code__c = 200;
            }

            insert paymentObj;
            at.Payment__c = paymentObj.id;
            
        }

        }catch(Exception e){
            system.debug('Exception :: ' + e.getMessage() + '::' + e.getStackTraceString());
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();
        }finally{
            if(pconfig.Enable_Logging__c){

                insert at;
            }
        }
    }

    public class PaymentException extends Exception{}

}