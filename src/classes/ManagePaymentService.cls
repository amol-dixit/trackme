/**
 * This class is responsible to provide all the transaction methods and based on the payment service provider, it routes requests to approprite helper classes.
 *
 * 
 */
global with sharing class ManagePaymentService {
    /**
     * This method is called from LWC component to perform the charge transaction api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.ChargeTransactionResponse chargeTransaction(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        System.debug('paymentDetails======>' + paymentDetails);
        ManagePaymentDTOService.Transaction_Reponse_Wrapper paymentResponse;
        if(paymentDetails.otherDetails.paymentserviceprovider == null || paymentDetails.otherDetails.paymentserviceprovider == ''){
            throw new AuthorizeNetServiceHelper.PaymentException('Payment Service Provider is not configured. Please contact system administrator.');
        }
        
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherDetails.paymentserviceprovider);
        API_Tracker__c at = new API_Tracker__c();

        try{
            paymentDetails.serviceChargeTransaction = false;
            paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).chargeTransaction(paymentDetails);

            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            System.debug('paymentResponse==>' + paymentResponse);

            if(paymentResponse.issuccess){
                Payment__c paymentObj = new Payment__c();
                ctrObj.success = true;
                ctrObj.authCode = paymentResponse.authCode;
                ctrObj.transactionId = paymentResponse.transId;
                ctrObj.accountNumber = paymentResponse.accountNumber;
                ctrObj.accountType = paymentResponse.accountType;
                paymentObj.Card_Services_Fee__c = paymentResponse.serviceFee;
                paymentObj.TrackPay_Transaction_Id__c = paymentResponse.trackpayTransactionId;
                paymentObj.Card_Services_Fee_Response__c = paymentResponse.cardServicesResponse;
                
                paymentObj.Amount__c = paymentResponse.amount;
                paymentObj.put(paymentDetails.otherdetails.fieldapiname, paymentDetails.otherdetails.refId);
                paymentObj.SObect_API_Name__c = paymentDetails.otherdetails.objectapiname;
                paymentObj.Transaction_Id__c = ctrObj.transactionId;
                paymentObj.Source__c = paymentDetails.otherDetails.paymentserviceprovider;
                paymentObj.Payment_Date__c = System.today();
                paymentObj.Email__c = paymentDetails.carddetails.cardEmail;
                paymentObj.RecordtypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Individual Payment').getRecordTypeId();

                paymentObj.Customer_Id__c = paymentDetails.otherdetails.refId;
                paymentObj.Card_Type__c = paymentResponse.accountType;
                paymentObj.Card_Number__c = paymentResponse.accountNumber;
                paymentObj.Transaction_Status__c = 'Approved';
        
                paymentObj.Ship_To_Address__c = paymentDetails.addressdetails.BillingStreet;
                paymentObj.Ship_To_City__c = paymentDetails.addressdetails.BillingCity;
                paymentObj.Ship_To_State__c = paymentDetails.addressdetails.BillingState;
                paymentObj.Ship_To_Zip__c = paymentDetails.addressdetails.BillingPostalCode;
                paymentObj.Ship_To_Country__c = paymentDetails.addressdetails.BillingCountry;
        
                paymentObj.Bill_To_Address__c = paymentDetails.addressdetails.BillingStreet;
                paymentObj.Bill_To_City__c = paymentDetails.addressdetails.BillingCity;
                paymentObj.Bill_To_State__c = paymentDetails.addressdetails.BillingState;
                paymentObj.Bill_To_Zip__c = paymentDetails.addressdetails.BillingPostalCode;
                paymentObj.Bill_To_Country__c = paymentDetails.addressdetails.BillingCountry;
                paymentObj.Bill_To_First_Name__c = paymentDetails.carddetails.cardHolderFirstName;
                paymentObj.Bill_To_Last_Name__c = paymentDetails.carddetails.cardHolderLastName;
                paymentObj.Account_Type__c = paymentDetails.bankdetails.accountType;
                paymentObj.Routing_Number__c = paymentDetails.bankdetails.routingNumber;
                paymentObj.Account_Number__c = paymentDetails.bankdetails.accountNumber;
                paymentObj.Name_on_Account__c = paymentDetails.bankdetails.nameOnAccount;
                
                paymentObj.Custom_1__c = paymentDetails.otherDetails.custom1;
                paymentObj.Custom_2__c = paymentDetails.otherDetails.custom2;
                paymentObj.Custom_3__c = paymentDetails.otherDetails.custom3;
                paymentObj.Custom_4__c = paymentDetails.otherDetails.custom4;
                paymentObj.Transaction_Key__c = paymentDetails.otherDetails.transactionkey;

                ManagePaymentServiceHelper.handleInsertDML(new List<Payment__c> { paymentObj });
                at.Payment__c = paymentObj.id;

                System.debug('paymentObj==>' + paymentObj.id);
        
                ctrObj.paymentObj = paymentObj;

                ctrObj.address = paymentObj.Bill_To_Address__c;
                ctrObj.city = paymentObj.Bill_To_City__c;
                ctrObj.state = paymentObj.Bill_To_State__c;
                ctrObj.zip = paymentObj.Bill_To_Zip__c;
                ctrObj.country = paymentObj.Bill_To_Country__c;
            }else{
                ctrObj.success = false;
                ctrObj.responseText = paymentResponse.responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }

        }
        return ctrObj;
    }

    /**
     * This method is called from LWC component to perform the refund transaction api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.TransactionResponse refundTransaction(Id paymentId){

        List<Payment__c> paymentList = Database.query('SELECT Subscription__r.TrackPay_Subscription_Id__c, Payment_Number__c, Subscription__r.TrackPay_Customer_Profile_Id__c, Subscription__r.TrackPay_Customer_Payment_Profile_Id__c, Subscription__c, Subscription__r.Routing_Number__c, Subscription__r.Account_Number__c, Subscription__r.Name_on_Account__c, Routing_Number__c, Account_Number__c, Name_on_Account__c, Card_Services_Fee__c, TrackPay_Transaction_Id__c, SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where id =: paymentId');
        ManagePaymentDTOService.TransactionResponse tr = new ManagePaymentDTOService.TransactionResponse();
        tr.success = false;
        tr.message = '';
        if(!paymentList.isempty()){
            Payment_Configuration__c pconfig;
            ManagePaymentDTOService.Transaction_Reponse_Wrapper paymentResponse;
            pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);

            paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentList[0].Source__c.replace('.', '')).refundTransaction(paymentList)[0];

    
            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

			System.debug('paymentResponse==>' + paymentResponse);
            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
            if(paymentResponse.issuccess){
                ctrObj.success = true;
                ctrObj.authCode = paymentResponse.authCode;
                ctrObj.transactionId = paymentResponse.transId;
                ctrObj.accountNumber = paymentResponse.accountNumber;
                ctrObj.accountType = paymentResponse.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = paymentResponse.responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Refund_Response__c = paymentResponse.responseMessage, Refund_Result_Code__c = paymentResponse.resultCode));
                at.Error_Message__c = paymentResponse.responseMessage;

            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Refund_Response__c = paymentResponse.responseMessage, Refund_Result_Code__c = paymentResponse.resultCode, Refunded__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;

                if(paymentResponse.trackpayTransactionId != null){
                    paymentclone.TrackPay_Transaction_Id__c = paymentResponse.trackpayTransactionId;
                    paymentclone.Card_Services_Fee__c = -paymentclone.Card_Services_Fee__c;
                    paymentclone.Card_Services_Fee_Response__c = paymentResponse.cardServicesResponse;
                }
                
                paymentclone.Transaction_Id__c = paymentResponse.transId;
                paymentclone.Transaction_Status__c = 'Refunded';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Refund_Result_Code__c = paymentResponse.resultCode;
                paymentclone.Refund_Response__c = paymentResponse.responseMessage;
                paymentclone.Refunded__c = true;
                upsertPaymentList.add(paymentclone);
            }

            ManagePaymentServiceHelper.handleUpsertDML(upsertPaymentList);


            tr.success = ctrObj.success;
            tr.message = paymentResponse.responseMessage;


            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }


        }
        return tr;

    }

    /**
     * This method is called from LWC component to perform the void transaction api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.TransactionResponse voidTransaction(Id paymentId){

        List<Payment__c> paymentList = Database.query('SELECT Subscription__c, Account_Type__c, Routing_Number__c, Account_Number__c, Name_on_Account__c, TrackPay_Transaction_Id__c, Card_Services_Fee__c, SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where id =: paymentId');
        ManagePaymentDTOService.TransactionResponse tr = new ManagePaymentDTOService.TransactionResponse();
        tr.message = '';
        if(!paymentList.isempty()){

             Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
             ManagePaymentDTOService.Transaction_Reponse_Wrapper paymentResponse;
            paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentList[0].Source__c.replace('.', '')).voidTransaction(paymentList)[0];

            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

			System.debug('paymentResponse==>' + paymentResponse);
            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            System.debug('at===>' + at);

            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
            
            if(paymentResponse.issuccess){
                ctrObj.success = true;
                ctrObj.authCode = paymentResponse.authCode;
                ctrObj.transactionId = paymentResponse.transId;
                ctrObj.accountNumber = paymentResponse.accountNumber;
                ctrObj.accountType = paymentResponse.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = paymentResponse.responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Void_Response__c = paymentResponse.responseMessage, Void_Result_Code__c = paymentResponse.resultCode));
            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Void_Response__c = paymentResponse.responseMessage, Void_Result_Code__c = paymentResponse.resultCode, Voided__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;
                paymentclone.Transaction_Id__c = paymentResponse.transId;
                if(paymentResponse.trackpayTransactionId != null){
                    paymentclone.TrackPay_Transaction_Id__c = paymentResponse.trackpayTransactionId;
                    paymentclone.Card_Services_Fee__c = -paymentclone.Card_Services_Fee__c;
                    paymentclone.Card_Services_Fee_Response__c = paymentResponse.cardServicesResponse;
                }
                paymentclone.Transaction_Status__c = 'Voided';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Void_Result_Code__c = paymentResponse.resultCode;
                paymentclone.Void_Response__c = paymentResponse.responseMessage;
                paymentclone.Voided__c = true;
                upsertPaymentList.add(paymentclone);
            }
            ManagePaymentServiceHelper.handleUpsertDML(upsertPaymentList);
            tr.message = paymentResponse.responseMessage;
            tr.success = paymentResponse.issuccess;

            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }

        }

        return tr;
    }

   /**
     * This method is called from LWC component to perform the create Subscription api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.SubscriptionTransactionResponse createSubscription(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.SubscriptionTransactionResponse ctrObj = new ManagePaymentDTOService.SubscriptionTransactionResponse();

        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
        API_Tracker__c at = new API_Tracker__c();
        Payment_Configuration__c pconfig;
        try{
            if(paymentDetails.otherDetails.paymentserviceprovider == null || paymentDetails.otherDetails.paymentserviceprovider == ''){
                throw new AuthorizeNetServiceHelper.PaymentException('Payment Service Provider is not configured. Please contact system administrator.');
            }
            pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

            ManagePaymentDTOService.Sub_Reponse_Wrapper paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).createSubscription(paymentDetails);

            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            System.debug('paymentResponse==>' + paymentResponse);

            if(paymentResponse.issuccess){

                ctrObj.success = true;

                Subscription__c subscriptionObj = new Subscription__c();
                subscriptionObj.put(paymentDetails.otherdetails.fieldapiname, paymentDetails.otherdetails.refId);
                subscriptionObj.Subscription_Id__c = paymentResponse.subscriptionId;
                subscriptionObj.Start_Date__c = Date.valueOf(paymentDetails.subDetails.startDate);
                if(paymentDetails.carddetails.cardNumber != null)
                subscriptionObj.Card_Number__c = 'XXXXX'+ paymentDetails.carddetails.cardNumber.replaceAll(' ','').right(4);
                subscriptionObj.Name = paymentDetails.subDetails.subname;
                subscriptionObj.Customer_Profile_Id__c = paymentResponse.profile.customerProfileId;
                subscriptionObj.Customer_Payment_ProfileId__c = paymentResponse.profile.customerPaymentProfileId;
                subscriptionObj.Length__c = paymentDetails.subdetails.unit == 'Monthly' ? '1' : (paymentDetails.subdetails.unit == 'Weekly' ? '7' : '');
                subscriptionObj.Occurrances__c = Decimal.valueOf(paymentDetails.subDetails.occurrances);
                subscriptionObj.Unit__c = paymentDetails.subDetails.unit;
                subscriptionObj.Amount__c = paymentResponse.amount;
                subscriptionObj.Card_Services_Fee__c = paymentResponse.serviceCharge;
                subscriptionObj.TrackPay_Subscription_Id__c = paymentResponse.trackPaySubscriptionId;
                subscriptionObj.TrackPay_Customer_Profile_Id__c = paymentResponse.trackPayCustomerProfileId;
                subscriptionObj.TrackPay_Customer_Payment_Profile_Id__c = paymentResponse.trackPayCustomerPaymentProfileId;

                subscriptionObj.Account_Type__c = paymentDetails.bankdetails.accountType;
                subscriptionObj.Routing_Number__c = paymentDetails.bankdetails.routingNumber;
                subscriptionObj.Account_Number__c = paymentDetails.bankdetails.accountNumber;
                subscriptionObj.Name_on_Account__c = paymentDetails.bankdetails.nameOnAccount;


                //insert subscriptionObj;
                ManagePaymentServiceHelper.handleInsertDML(new List<Subscription__c> { subscriptionObj });
                at.Subscription__c = subscriptionObj.id;
                System.debug('subscriptionObj==>' + subscriptionObj.id);
        
                ctrObj.subObj = subscriptionObj;
                ctrObj.startDate = subscriptionObj.Start_Date__c;
                ctrObj.subId = subscriptionObj.Subscription_Id__c;
                ctrObj.unit = subscriptionObj.Unit__c;
                ctrObj.occurance = subscriptionObj.Occurrances__c;
                ctrObj.length = subscriptionObj.Length__c;

            }else{
                ctrObj.success = false;
                ctrObj.responseText = paymentResponse.responseString;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }

        }
        return ctrObj;
    }

    /**
     * This method is called from LWC component to perform the update Subscription api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.SubscriptionTransactionResponse updateSubscription(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.SubscriptionTransactionResponse ctrObj = new ManagePaymentDTOService.SubscriptionTransactionResponse();

        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
        Payment_Configuration__c pconfig;
        API_Tracker__c at = new API_Tracker__c();

        try{
            if(paymentDetails.otherDetails.paymentserviceprovider == 'Authorize.Net'){
                pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.Sub_Reponse_Wrapper paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).updateSubscription(paymentDetails);

            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            at.Subscription__r = new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId);

            System.debug('paymentResponse==>' + paymentResponse);

            if(paymentResponse.issuccess){
                upsert new Subscription__c(Card_Number__c = 'XXXXX'+ paymentDetails.carddetails.cardNumber.replaceAll(' ','').right(4), Subscription_Id__c = paymentDetails.otherdetails.subscriptionId) Subscription_Id__c;
                ctrObj.success = true;
                ctrObj.subObj = [select id, Start_Date__c, Subscription_Id__c, Customer_Profile_Id__c, Customer_Payment_ProfileId__c, Length__c, Occurrances__c,Unit__c, Amount__c from Subscription__c  where Subscription_Id__c =: paymentDetails.otherdetails.subscriptionId limit 1];
                
                ctrObj.startDate = ctrObj.subObj.Start_Date__c;
                ctrObj.subId = ctrObj.subObj.Subscription_Id__c;
                ctrObj.unit = ctrObj.subObj.Unit__c;
                ctrObj.occurance = ctrObj.subObj.Occurrances__c;
                ctrObj.length = ctrObj.subObj.Length__c;

            }else{
                ctrObj.success = false;
                ctrObj.responseText = paymentResponse.responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }

        }
        return ctrObj;
    }

    /**
     * This method is called from LWC component to perform the cancel Subscription api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.SubscriptionTransactionResponse cancelSubscription(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.SubscriptionTransactionResponse ctrObj = new ManagePaymentDTOService.SubscriptionTransactionResponse();

        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
        Payment_Configuration__c pconfig;
        API_Tracker__c at = new API_Tracker__c();

        try{
            if(paymentDetails.otherDetails.paymentserviceprovider == null || paymentDetails.otherDetails.paymentserviceprovider == ''){
                throw new AuthorizeNetServiceHelper.PaymentException('Payment Service Provider is not configured. Please contact system administrator.');
            }

            if(paymentDetails.otherDetails.paymentserviceprovider == 'Authorize.Net'){
                pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.Sub_Reponse_Wrapper paymentResponse = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).cancelSubscription(paymentDetails);

            at.Request_Body__c = paymentResponse.requestString;
            at.Response_Body__c = paymentResponse.responseString;
            at.Status_Code__c = paymentResponse.statusCode;
            at.TrackPay_Request_Body__c = paymentResponse.trackpayrequestString;
            at.TrackPay_Response_Body__c = paymentResponse.trackpayresponseString;
            at.TrackPay_Status_Code__c = paymentResponse.trackpaystatusCode;

            at.Subscription__r = new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId);

            System.debug('paymentResponse==>' + paymentResponse);

            if(paymentResponse.issuccess){
                ctrObj.success = true;
                upsert (new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId, Status__c = 'InActive')) Subscription_Id__c;

            }else{
                ctrObj.success = false;
                ctrObj.responseText = paymentResponse.responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(new List<API_Tracker__c> { at } );
            }

        }
        return ctrObj;
    }

    /**
     * This method is called from LWC component to perform the get Subscription api
     */
    @AuraEnabled
    public static ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.SubscriptionTransactionResponse ctrObj = new ManagePaymentDTOService.SubscriptionTransactionResponse();
        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
        return ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).getSubscriptions(paymentDetails);
    }

    /**
     * This method is called from LWC component and returns the decrupted payment url.
     */
    @AuraEnabled
    public static ManagePaymentDTOService.PaymentData decryptURL(String encryptedData, String sobjectAPIName, String paymentserviceprovider){
        System.debug('sobjectAPIName===>' + sobjectAPIName);
        System.debug('paymentserviceprovider===>' +paymentserviceprovider);
        

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(sobjectAPIName, paymentserviceprovider);
        encryptedData = encryptedData.replaceAll(' ', '+');
        System.debug('encryptedData===>' + encryptedData);
        ApexPages.PageReference ref = new ApexPages.PageReference('https://?'+Util.decrypt(encryptedData, pconfig.Encryption_Key__c));
        Map<String, String> params = ref.getParameters();
        system.debug('params===>' + params);

        ManagePaymentDTOService.PaymentData pdObj = new ManagePaymentDTOService.PaymentData();
        pdObj.amount = Decimal.valueOf(params.get('amount'));
        pdobj.street = params.get('street');
        pdobj.city = params.get('city');
        pdobj.state =  params.get('state');
        pdobj.zip = params.get('zip');
        pdobj.country = params.get('country');
        pdobj.email = params.get('email');
        pdobj.firstname =  params.get('firstname');
        pdobj.lastname = params.get('lastname');
        pdobj.product = params.get('product');
        pdobj.objectapiname = params.get('objectapiname');
        pdobj.fieldapiname = params.get('fieldapiname');
        pdobj.refId = params.get('refId');
        pdobj.company = params.get('company');
        pdobj.customerid = params.get('customerid');
        pdobj.subheader = params.get('subheader');
        pdobj.returl = params.get('returl');

        //Custom info
        pdobj.custom1 = params.get('custom1');
        pdobj.custom2 = params.get('custom2');
        pdobj.custom3 = params.get('custom3');
        pdobj.custom4 = params.get('custom4');
        pdobj.transactionkey = params.get('transactionkey');
        
        if(ManagePaymentServiceHelper.validatePayment(pdobj.transactionkey)){
            throw new PaymentException('Payment has been made already. Thank you.');
        }
        Date expirationDate = Date.valueOf(params.get('expiration'));
        if(System.today() > expirationDate){
            throw new PaymentException('Link has expired on '+ expirationDate);
        }
        return pdobj;
    }

    /**
     * This method is returns the data with the details. The api names are dynamic.
     * The payment can be configured to any SObject.
     */
    @AuraEnabled
    public static ManagePaymentDTOService.PaymentData retrieveRecord(Id recordId, String sobjectAPIName, String paymentserviceprovider){

        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(sobjectAPIName, paymentserviceprovider);
        String select1 = 'select';
        String query =   ' OwnerId,';
        query +=  (pconfig.Address_API_Name__c != null ? pconfig.Address_API_Name__c +',' : '');
        query += (pconfig.Amount_API_Name__c != null ? pconfig.Amount_API_Name__c +',' : '');
        query += (pconfig.City_API_Name__c != null ? pconfig.City_API_Name__c +',' : '');
        query += (pconfig.Company_API_Name__c != null ? pconfig.Company_API_Name__c +',' : '');
        query += (pconfig.Country_API_Name__c != null ? pconfig.Country_API_Name__c +',' : '');
        query += (pconfig.Customer_Id_API_Name__c != null ? pconfig.Customer_Id_API_Name__c +',' : '');
        query += (pconfig.Email_API_Name__c != null ? pconfig.Email_API_Name__c +',' : '');
        query += (pconfig.First_Name_API_Name__c != null ? pconfig.First_Name_API_Name__c +',' : '');
        query += (pconfig.Product_API_Name__c != null ? pconfig.Product_API_Name__c +',' : '');
        query += (pconfig.RefId_Api_Name__c != null ? pconfig.RefId_Api_Name__c +',' : '');
        query += (pconfig.Return_URL_API_Name__c != null ? pconfig.Return_URL_API_Name__c +',' : '');
        query += (pconfig.State_API_Name__c != null ? pconfig.State_API_Name__c +',' : '');
        query += (pconfig.Zip_API_Name__c != null ? pconfig.Zip_API_Name__c +',' : '');
        query += (pconfig.Last_Name_API_Name__c != null ? pconfig.Last_Name_API_Name__c +',' : '');
        query += (pconfig.Sub_Header_API_Name__c != null ? pconfig.Sub_Header_API_Name__c +',' : '');

        Set<String> tmpSet = New Set<String>(query.split(','));
        query = string.join(New List<String>(tmpSet),',');

        query = select1 + query.removeEnd(',');
        query += ' from '+ sobjectAPIName +' where id =: recordId';

        System.debug('query====>' + query);
        SObject record = Database.query(query);
        ManagePaymentDTOService.PaymentData pdObj = new ManagePaymentDTOService.PaymentData();
        pdObj.amount = (Decimal)fetchRecordData(record, pconfig.Amount_API_Name__c);
        pdobj.street = (String)fetchRecordData(record, pconfig.Address_API_Name__c);
        pdobj.city = (String)fetchRecordData(record, pconfig.City_API_Name__c);
        pdobj.state =  (String)fetchRecordData(record, pconfig.State_API_Name__c);
        pdobj.zip = (String)fetchRecordData(record, pconfig.Zip_API_Name__c);
        pdobj.country = (String)fetchRecordData(record, pconfig.Country_API_Name__c);
        pdobj.email = (String)fetchRecordData(record, pconfig.Email_API_Name__c) == null ? '' : (String)fetchRecordData(record, pconfig.Email_API_Name__c);
        pdobj.firstname =  (String)fetchRecordData(record, pconfig.First_Name_API_Name__c) == null ? '' : (String)fetchRecordData(record, pconfig.First_Name_API_Name__c);
        pdobj.lastname = (String)fetchRecordData(record, pconfig.Last_Name_API_Name__c) == null ? '' : (String)fetchRecordData(record, pconfig.Last_Name_API_Name__c);
        pdobj.product = (String)fetchRecordData(record, pconfig.Product_API_Name__c);
        pdobj.objectapiname = pconfig.Object_Api_Name__c;
        pdobj.fieldapiname = pconfig.SObject_Payment_Lookup_API_Name__c;
        pdobj.refId = (String)fetchRecordData(record, pconfig.RefId_Api_Name__c);
        pdobj.company = (String)fetchRecordData(record, pconfig.Company_API_Name__c);
        pdobj.customerid = (String)fetchRecordData(record, pconfig.Customer_Id_API_Name__c);
        pdobj.subheader = (String)fetchRecordData(record, pconfig.Sub_Header_API_Name__c);
        pdobj.returl = (String)fetchRecordData(record, pconfig.Return_URL_API_Name__c);
        if(pdobj.returl == null){
            pdobj.returl = pconfig.Return_URL__c;
        }
        //Custom info
        pdobj.custom1 = pconfig.Custom_1__c;
        pdobj.custom2 = pconfig.Custom_2__c;
        pdobj.custom3 = pconfig.Custom_3__c;
        pdobj.custom4 = pconfig.Custom_4__c;

        Map<String, Object> urlParamMap = new Map<String, Object>();
        urlParamMap.put('amount', String.valueOf(pdObj.amount));
        urlParamMap.put('street', pdObj.street);
        urlParamMap.put('city', pdObj.city);
        urlParamMap.put('state', pdObj.state);
        urlParamMap.put('zip', pdObj.zip);
        urlParamMap.put('email', pdObj.email == null ? '' : pdObj.email);
        urlParamMap.put('firstname', pdObj.firstname == null ? '' : pdObj.firstname);
        urlParamMap.put('lastname', pdObj.lastname == null ? '' : pdObj.lastname);
        urlParamMap.put('product', pdObj.product);
        urlParamMap.put('objectapiname', pconfig.Object_Api_Name__c);
        urlParamMap.put('fieldapiname', pconfig.SObject_Payment_Lookup_API_Name__c);
        urlParamMap.put('refid', pdObj.refid);
        urlParamMap.put('company', pdObj.company);
        urlParamMap.put('customerid', pconfig.Customer_Id_API_Name__c);
        urlParamMap.put('custom1', pconfig.Custom_1__c);
        urlParamMap.put('custom2', pconfig.Custom_2__c);
        urlParamMap.put('custom3', pconfig.Custom_3__c);
        urlParamMap.put('custom4', pconfig.Custom_4__c);
        urlParamMap.put('subheader', pdobj.subheader);
        urlParamMap.put('transactionkey', pdObj.refid + system.now());
        urlParamMap.put('returl', pdobj.returl);
        
        urlParamMap.put('expiration', String.valueOf(System.today() +  (pconfig.Expiration_Days__c == null ? 7 : Integer.valueOf(pconfig.Expiration_Days__c))));

        if(pconfig.Enable_Encrypted_Payment_URL__c){
            String encrypteddata = Util.encrypt(Util.generateURLParameters(urlParamMap), pconfig.Encryption_Key__c);
            System.debug('Encrypted Data=====>' + encrypteddata);
            pdobj.externalPaymentEncryptedURL = pconfig.Community_URL__c +'?data=' + encrypteddata;
        }
        pdobj.externalPaymentURL = pconfig.Community_URL__c +'?' + Util.generateURLParameters(urlParamMap);
        pdobj.enableencrption = pconfig.Enable_Encrypted_Payment_URL__c;
        System.debug('pdobj.externalPaymentURL=====>' + pdobj.externalPaymentURL);
        System.debug('pdobj.externalPaymentEncryptedURL=====>' + pdobj.externalPaymentEncryptedURL);

        return pdobj;

    }

    // Processed the Webhook
    public static void processWebhook(String requestbody){
        AuthorizeNetService.authorizeNetProcessWebhook(requestbody);
    }
    
    // This private method fetches the fields data for a specifed record dynamically.
    private static Object fetchRecordData(SObject record, String apiName){
        if(apiName == null || apiName == ''){
            return null;
        }
        List<String> fieldSplitList = apiName.split('\\.');
        System.debug('fieldSplitList==>' + fieldSplitList + ' == APINAME ==' + apiName);
        if(fieldSplitList.size() > 1){
            String fieldName = fieldSplitList[fieldSplitList.size() - 1];
            fieldSplitList.remove(fieldSplitList.size() - 1);
            SObject sObj;
            for(String field : fieldSplitList){
                sObj = record.getSObject(field);
            }
            return (sobj != null && hasSObjectField(fieldName, sobj)) ? sObj.get(fieldName) : null;
        }
        return hasSObjectField(apiName, record) ? record.get(apiName) : null;
    }
    public static boolean hasSObjectField(String fieldName, SObject so){
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
    }

    public class PaymentException extends Exception{}

}