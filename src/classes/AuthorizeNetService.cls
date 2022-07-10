/**
 * This class is responsible to serve all the transactions realated to Authorize.NET. 
 * It implements the PaymentServiceInterface
 * 
 */
public with sharing class AuthorizeNetService implements PaymentServiceInterface{

    /**
     * This method is reponsible to charge the transaction for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Transaction_Reponse_Wrapper chargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails){
        
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');
        if(paymentDetails.serviceChargeTransaction && Decimal.valueOf(licenseKeys[1]) == 0){
            return null;
        }

        Decimal serviceChargeAmount = ((Decimal.valueOf(licenseKeys[1])/100) * paymentDetails.otherdetails.amount);
        Decimal chargeAmount = paymentDetails.otherdetails.amount - serviceChargeAmount;

        ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processChargeTransaction(paymentDetails, '', chargeAmount, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c);
        if(trw.issuccess){
            trw.amount = chargeAmount;
            if(serviceChargeAmount != 0){
                paymentDetails.serviceChargeTransaction = true;
                ManagePaymentDTOService.Transaction_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processChargeTransaction(paymentDetails, licenseKeys[0], serviceChargeAmount, licenseKeys[2] , licenseKeys[3]);

                if(serviceChargeResponse != null ){
                    if(serviceChargeResponse.issuccess){
                        trw.serviceFee = serviceChargeAmount;
                        trw.trackpayTransactionId = serviceChargeResponse.transId;
                    }else{
                        trw.cardServicesResponse = serviceChargeResponse.cardServicesResponse;
                        trw.issuccess = false;
                    }
                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;
                }
            }
        }
        return trw;
    }

    /**
     * This method is reponsible to refund the transaction for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
     */
    public static List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> refundTransaction(List<Payment__c> paymentList ){
        List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> wrapperList = new List<ManagePaymentDTOService.Transaction_Reponse_Wrapper>();
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        for(Payment__c paymentObj :  paymentList){
            ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processRefundTransaction(new AuthorizeNetServiceHelper.PaymentDataWrapper(paymentObj, '', paymentObj.Amount__c, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c, paymentObj.Transaction_Id__c));
            if(trw.issuccess){

                if(paymentObj.Card_Services_Fee__c != 0 && paymentObj.TrackPay_Transaction_Id__c != null){
                    ManagePaymentDTOService.Transaction_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processRefundTransaction(new AuthorizeNetServiceHelper.PaymentDataWrapper(paymentObj, licenseKeys[0], paymentObj.Card_Services_Fee__c, licenseKeys[2] , licenseKeys[3], paymentObj.TrackPay_Transaction_Id__c));

                    if(serviceChargeResponse.issuccess){
                        trw.trackpayTransactionId = serviceChargeResponse.transId;
                        trw.serviceFee = paymentObj.Card_Services_Fee__c;
                        trw.cardServicesResponse = serviceChargeResponse.responseMessage;
                        trw.issuccess = true;
                    }else{
                        trw.issuccess = false;
                    }
                    trw.cardServicesResponse = serviceChargeResponse.responseString;

                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;
                }
            }
            wrapperList.add(trw);

        }
        return wrapperList;
    }

    /**
     * This method is reponsible to void the transaction for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
     */
    public static List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> voidTransaction(List<Payment__c> paymentList){

        List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> wrapperList = new List<ManagePaymentDTOService.Transaction_Reponse_Wrapper>();
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        for(Payment__c paymentObj :  paymentList){
            ManagePaymentDTOService.Transaction_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processVoidTransaction(new AuthorizeNetServiceHelper.PaymentDataWrapper(paymentObj, '', paymentObj.Amount__c, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c, paymentObj.Transaction_Id__c));
            System.debug('BEFORE ====> trw' + trw);
            if(trw.issuccess){

                if(paymentObj.Card_Services_Fee__c != 0 && paymentObj.TrackPay_Transaction_Id__c != null){

                    ManagePaymentDTOService.Transaction_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processVoidTransaction(new AuthorizeNetServiceHelper.PaymentDataWrapper(paymentObj, licenseKeys[0], paymentObj.Card_Services_Fee__c, licenseKeys[2] , licenseKeys[3], paymentObj.TrackPay_Transaction_Id__c));

                    if(serviceChargeResponse.issuccess){
                        trw.trackpayTransactionId = serviceChargeResponse.transId;
                        trw.serviceFee = paymentObj.Card_Services_Fee__c;
                        trw.cardServicesResponse = serviceChargeResponse.responseMessage;
                        trw.issuccess = true;
                    }else{
                        trw.issuccess = false;
                    }

                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;
                }
            }

            System.debug('trw=========>' + trw);
            wrapperList.add(trw);
        }
        return wrapperList;

    }

    /**
     * This method is reponsible to create a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.Sub_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper createSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails ){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        Decimal serviceChargeAmount = ((Decimal.valueOf(licenseKeys[1])/100) * paymentDetails.subDetails.amount);
        Decimal chargeAmount = paymentDetails.subDetails.amount - serviceChargeAmount;

        ManagePaymentDTOService.Sub_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processSubscription(paymentDetails, '', chargeAmount, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c);
        if(trw.issuccess){
            trw.amount = chargeAmount;
            if(serviceChargeAmount != 0){
            ManagePaymentDTOService.Sub_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processSubscription(paymentDetails, licenseKeys[0], serviceChargeAmount, licenseKeys[2] , licenseKeys[3] );

                if(serviceChargeResponse != null ){
                    if(serviceChargeResponse.issuccess){
                        trw.serviceCharge = serviceChargeAmount;
                        trw.trackPaySubscriptionId = serviceChargeResponse.subscriptionId;
                        trw.trackPayCustomerProfileId = serviceChargeResponse.profile.customerProfileId;
                        trw.trackPayCustomerPaymentProfileId = serviceChargeResponse.profile.customerPaymentProfileId;

                    }else{
                        trw.cardServicesResponse = serviceChargeResponse.responseString;
                    }
                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;                }
            }
        }
        return trw;
    }

        /**
     * This method is reponsible to update a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.PaymentDetails : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper updateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        ManagePaymentDTOService.Sub_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processUpdateSubscription(paymentDetails, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c, paymentDetails.otherdetails.subscriptionId);
        if(trw.issuccess){
            if(paymentDetails.otherdetails.trackPaySubscriptionId != null){
                ManagePaymentDTOService.Sub_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processUpdateSubscription(paymentDetails, licenseKeys[2] , licenseKeys[3], paymentDetails.otherdetails.trackPaySubscriptionId);

                if(serviceChargeResponse != null ){
                    if(serviceChargeResponse.issuccess){
                        trw.trackPaySubscriptionId = serviceChargeResponse.subscriptionId;
                    }else{
                        trw.cardServicesResponse = serviceChargeResponse.responseString;
                        trw.issuccess = false;
                    }
                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;
            
                }
            }
        }
        return trw;

    }


    /**
     * This method is reponsible to cancel a Subscription for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.SubscriptionWrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.Sub_Reponse_Wrapper cancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
        List<String> licenseKeys = Util.decrypt(pconfig.Auth_License_Key__c, null).split('-');

        ManagePaymentDTOService.Sub_Reponse_Wrapper trw = AuthorizeNetServiceHelper.processCancelSubscription(paymentDetails, pconfig.Auth_API_Login_Id__c, pconfig.Auth_Transaction_Key__c, paymentDetails.otherdetails.subscriptionId);
        if(trw.issuccess){
            if(paymentDetails.otherdetails.trackPaySubscriptionId != null){
                ManagePaymentDTOService.Sub_Reponse_Wrapper serviceChargeResponse = AuthorizeNetServiceHelper.processCancelSubscription(paymentDetails, licenseKeys[2] , licenseKeys[3], paymentDetails.otherdetails.trackPaySubscriptionId);

                if(serviceChargeResponse != null ){
                    if(serviceChargeResponse.issuccess){
                        trw.trackPaySubscriptionId = serviceChargeResponse.subscriptionId;
                    }else{
                        trw.cardServicesResponse = serviceChargeResponse.responseString;
                        trw.issuccess = false;
                    }
                    trw.trackPayResponseString = serviceChargeResponse.responseString;
                    trw.trackPaystatusCode = serviceChargeResponse.statuscode;

                }
            }
        }
        return trw;
    }

    /**
     * This method is reponsible to get a related Subscriptions for Authorize.NET. It accepts the PaymentDetails wrapper with all the details.
     * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
     * @return ManagePaymentDTOService.SubscriptionWrapper : It returns the wrapper with the Success/Failure response.
     */
    public static ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(ManagePaymentDTOService.PaymentDetails paymentDetails){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

        String query = 'select TrackPay_Subscription_Id__c, Amount__c,Card_Number__c,CreatedById,CreatedDate,Customer_Payment_ProfileId__c,Customer_Profile_Id__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Length__c,Name,Occurrances__c,Opportunity__c,OwnerId,Record_Id__c,Start_Date__c,Status__c,Subscription_Id__c,SystemModstamp,Unit__c from Subscription__c where '+paymentDetails.otherdetails.fieldapiname + '=\''+paymentDetails.otherdetails.refId+'\' and status__c = \'Active\'';
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
            sd.trackPaySubscriptionId = sub.TrackPay_Subscription_Id__c;
            subscriptionDetails.add(sd);
        }
        wrapper.subscriptionDetails = subscriptionDetails;
        return wrapper;

    }
    /**
     * This method is reponsible to get the Subscription payment updates from the Authorize.NET.
     * @param  requestbody : This is the request body returned from the Authorize.net webhook.
     */
    public static void authorizeNetProcessWebhook(String requestbody){
        API_Tracker__c at = new API_Tracker__c();
        at.Response_Body__c = requestbody;

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(null, 'Authorize.Net');

        try{
            ManagePaymentDTOService.Notification values = (ManagePaymentDTOService.Notification) System.JSON.deserialize(requestbody.replaceall('uFEFF','').replaceall('\\\\','').replaceall('﻿',''), ManagePaymentDTOService.Notification.class);

        Http http = new Http();
        String json=        '{'+
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
            List<Subscription__c> subList = [select Contact__c,Lead__c, Opportunity__c  from Subscription__c where Subscription_Id__c =: tdresp.transaction1.subscription.id];
            if(!subList.isempty()){
                paymentObj.Contact__c = subList[0].Contact__c;
                paymentObj.Lead__c = subList[0].Lead__c;
                paymentObj.Opportunity__c = subList[0].Opportunity__c;
            }

            paymentObj.Subscription__r = new Subscription__c(Subscription_Id__c = tdresp.transaction1.subscription.id);
            paymentObj.Payment_Number__c = tdresp.transaction1.subscription.payNum;
            
            paymentObj.Source__c = 'Authorize.Net';
            paymentObj.Payment_Date__c = System.today();

            if(tdresp.transaction1.customer != null){
                paymentObj.Customer_Id__c = tdresp.transaction1.customer.id;
            }
            System.debug('tdresp.transaction1===>' + tdresp.transaction1);
            if(tdresp.transaction1.payment.creditCard != null){
                paymentObj.Card_Type__c = tdresp.transaction1.payment.creditCard.cardType;
                paymentObj.Card_Number__c = tdresp.transaction1.payment.creditCard.cardNumber;
            }
            if(tdresp.transaction1.payment.bankAccount != null){
                paymentObj.Account_Number__c = tdresp.transaction1.payment.bankAccount.accountNumber;
                paymentObj.Routing_Number__c = tdresp.transaction1.payment.bankAccount.routingNumber;
                paymentObj.Name_on_Account__c = tdresp.transaction1.payment.bankAccount.nameOnAccount;
            }
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
            ManagePaymentServiceHelper.handleInsertDML(new List<Payment__c> { paymentObj});
            at.Payment__c = paymentObj.id;
            
        }

        }catch(Exception e){
            system.debug('Exception :: ' + e.getMessage() + '::' + e.getStackTraceString());
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();
        }finally{
            if(pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at });
            }
        }
    }

    // Payment Exceptions
    public class PaymentException extends Exception{}

}