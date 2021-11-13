global without sharing class ManagePaymentService {
    @AuraEnabled
    public static ManagePaymentDTOService.ChargeTransactionResponse chargeTransaction(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        Payment_Configuration__c pconfig;
        if(paymentDetails.otherDetails.paymentserviceprovider == null || paymentDetails.otherDetails.paymentserviceprovider == ''){
            throw new AuthorizeNetServiceHelper.PaymentException('Payment Service Provider is not configured. Please contact system administrator.');
        }
        if(paymentDetails.otherDetails.paymentserviceprovider == 'Authorize.Net'){
            pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
        }
        API_Tracker__c at = new API_Tracker__c();

        try{

            ManagePaymentDTOService.Transaction_Reponse_Wrapper values = AuthorizeNetServiceHelper.authorizeNetChargeTransaction(paymentDetails, pconfig);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;
            System.debug('values==>' + values);
            String responseMessage = '';

            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }

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
                ctrObj.success = true;
                ctrObj.authCode = values.transactionResponse.authCode;
                ctrObj.transactionId = values.transactionResponse.transId;
                ctrObj.accountNumber = values.transactionResponse.accountNumber;
                ctrObj.accountType = values.transactionResponse.accountType;

                Payment__c paymentObj = new Payment__c();
                paymentObj.Amount__c = paymentDetails.otherdetails.amount;
                paymentObj.put(paymentDetails.otherdetails.fieldapiname, paymentDetails.otherdetails.refId);
                paymentObj.SObect_API_Name__c = paymentDetails.otherdetails.objectapiname;
                paymentObj.Transaction_Id__c = ctrObj.transactionId;
                paymentObj.Source__c = paymentDetails.otherDetails.paymentserviceprovider;
                paymentObj.Payment_Date__c = System.today();
                paymentObj.Email__c = paymentDetails.carddetails.cardEmail;
                paymentObj.RecordtypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosById().get('Individual Payment').getRecordTypeId();

                paymentObj.Customer_Id__c = paymentDetails.otherdetails.refId;
                paymentObj.Card_Type__c = values.transactionResponse.accountType;
                paymentObj.Card_Number__c = values.transactionResponse.accountNumber;
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
                
                insert paymentObj;
                at.Payment__c = paymentObj.id;

        
                System.debug('paymentObj==>' + paymentObj.id);
        
                ctrObj.paymentObj = paymentObj;
            }else{
                ctrObj.success = false;
                ctrObj.responseText = responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){

                insert at;
            }

        }
        return ctrObj;
    }

    @AuraEnabled
    public static ManagePaymentDTOService.TransactionResponse refundTransaction(Id paymentId){

        List<Payment__c> paymentList = Database.query('SELECT SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where id =: paymentId');
        ManagePaymentDTOService.TransactionResponse tr = new ManagePaymentDTOService.TransactionResponse();
        tr.success = false;
        tr.message = '';
        if(!paymentList.isempty()){
            Payment_Configuration__c pconfig;
            if(paymentList[0].Source__c == 'Authorize.Net'){
                pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
            }
    
            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

            ManagePaymentDTOService.Transaction_Reponse_Wrapper values = AuthorizeNetServiceHelper.authorizeNetRefundTransaction(paymentList[0], pconfig);
			System.debug('values==>' + values);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;

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
    
            if(ctrObj.success != false && values.messages.resultCode == 'Ok' && (values.transactionResponse.errors == null || values.transactionResponse.errors.isempty())){
                ctrObj.success = true;
                ctrObj.authCode = values.transactionResponse.authCode;
                ctrObj.transactionId = values.transactionResponse.transId;
                ctrObj.accountNumber = values.transactionResponse.accountNumber;
                ctrObj.accountType = values.transactionResponse.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Refund_Response__c = responseMessage, Refund_Result_Code__c = values.messages.resultCode));
                at.Error_Message__c = responseMessage;

            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Refund_Response__c = responseMessage, Refund_Result_Code__c = values.messages.resultCode, Refunded__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;
                paymentclone.Transaction_Id__c = values.transactionResponse.transId;
                paymentclone.Transaction_Status__c = 'Refunded';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Refund_Result_Code__c = values.messages.resultCode;
                paymentclone.Refund_Response__c = responseMessage;
                paymentclone.Refunded__c = true;
                upsertPaymentList.add(paymentclone);
            }

            upsert upsertPaymentList;

            tr.success = ctrObj.success;
            tr.message = responseMessage;


            if(pconfig == null || pconfig.Enable_Logging__c){
                insert at;
            }


        }
        return tr;

    }


    @AuraEnabled
    public static ManagePaymentDTOService.TransactionResponse voidTransaction(Id paymentId){

        List<Payment__c> paymentList = Database.query('SELECT SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where id =: paymentId');
        ManagePaymentDTOService.TransactionResponse tr = new ManagePaymentDTOService.TransactionResponse();
        tr.success = false;
        tr.message = '';
        if(!paymentList.isempty()){

            Payment_Configuration__c pconfig;

            if(paymentList[0].Source__c == 'Authorize.Net'){
                pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
            }
    
            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

            ManagePaymentDTOService.Transaction_Reponse_Wrapper values = AuthorizeNetServiceHelper.authorizeNetVoidTransaction(paymentList[0], pconfig);

			System.debug('values==>' + values);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;

            String responseMessage = '';
            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
            
            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    if(message.code != '1'){
                        ctrObj.success = false;
                    }else{
                        ctrObj.success = true;
                    }
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }
    
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
                ctrObj.success = true;
                ctrObj.authCode = values.transactionResponse.authCode;
                ctrObj.transactionId = values.transactionResponse.transId;
                ctrObj.accountNumber = values.transactionResponse.accountNumber;
                ctrObj.accountType = values.transactionResponse.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Void_Response__c = responseMessage, Void_Result_Code__c = values.messages.resultCode));
            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Void_Response__c = responseMessage, Void_Result_Code__c = values.messages.resultCode, Voided__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;
                paymentclone.Transaction_Id__c = values.transactionResponse.transId;
                paymentclone.Transaction_Status__c = 'Voided';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Void_Result_Code__c = values.messages.resultCode;
                paymentclone.Void_Response__c = responseMessage;
                paymentclone.Voided__c = true;
                upsertPaymentList.add(paymentclone);
            }

            upsert upsertPaymentList;
            tr.success = ctrObj.success;
            tr.message = responseMessage;

            if(pconfig == null || pconfig.Enable_Logging__c){

                insert at;
            }

        }

        return tr;
    }

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
            if(paymentDetails.otherDetails.paymentserviceprovider == 'Authorize.Net'){
                pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }

            //Payment_Configuration__c pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

            ManagePaymentDTOService.Sub_Reponse_Wrapper values = AuthorizeNetServiceHelper.authorizeNetCreateSubscription(paymentDetails, pconfig);        
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;

            System.debug('values==>' + values);
            String responseMessage = '';

            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }

            responseMessage += '\n';

            if(values.messages.resultCode == 'Ok' && values.messages.message[0].code == 'I00001'){
                ctrObj.success = true;

                Subscription__c subscriptionObj = new Subscription__c();
                subscriptionObj.put(paymentDetails.otherdetails.fieldapiname, paymentDetails.otherdetails.refId);
                subscriptionObj.Subscription_Id__c = values.subscriptionId;
                subscriptionObj.Start_Date__c = Date.valueOf(paymentDetails.subDetails.startDate);
                subscriptionObj.Customer_Profile_Id__c = values.profile.customerProfileId;
                subscriptionObj.Card_Number__c = 'XXXXX'+ paymentDetails.carddetails.cardNumber.replaceAll(' ','').right(4);
                subscriptionObj.Name = paymentDetails.subDetails.subname;
                subscriptionObj.Customer_Profile_Id__c = values.profile.customerProfileId;
                subscriptionObj.Customer_Payment_ProfileId__c = values.profile.customerPaymentProfileId;
                subscriptionObj.Length__c = paymentDetails.subdetails.unit == 'Monthly' ? '1' : (paymentDetails.subdetails.unit == 'Weekly' ? '7' : '');
                subscriptionObj.Occurrances__c = Decimal.valueOf(paymentDetails.subDetails.occurrances);
                subscriptionObj.Unit__c = paymentDetails.subDetails.unit;
                subscriptionObj.Amount__c = paymentDetails.subDetails.amount;
                insert subscriptionObj;
                at.Subscription__c = subscriptionObj.id;

                System.debug('subscriptionObj==>' + subscriptionObj.id);
        
                ctrObj.subObj = subscriptionObj;
            }else{
                ctrObj.success = false;
                ctrObj.responseText = responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){

                insert at;
            }

        }
        return ctrObj;
    }

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
                pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.Sub_Reponse_Wrapper values = AuthorizeNetServiceHelper.authorizeNetUpdateSubscription(paymentDetails, pconfig);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;
            at.Subscription__r = new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId);

            

            System.debug('values==>' + values);
            String responseMessage = '';

            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }

            responseMessage += '\n';

            if(values.messages.resultCode == 'Ok' && values.messages.message[0].code == 'I00001'){
                upsert new Subscription__c(Card_Number__c = 'XXXXX'+ paymentDetails.carddetails.cardNumber.replaceAll(' ','').right(4), Subscription_Id__c = paymentDetails.otherdetails.subscriptionId) Subscription_Id__c;
                ctrObj.success = true;
                ctrObj.subObj = [select id, Start_Date__c, Subscription_Id__c, Customer_Profile_Id__c, Customer_Payment_ProfileId__c, Length__c, Occurrances__c,Unit__c, Amount__c from Subscription__c  where Subscription_Id__c =: paymentDetails.otherdetails.subscriptionId limit 1];    
    
            }else{
                ctrObj.success = false;
                ctrObj.responseText = responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){

                insert at;
            }

        }
        return ctrObj;
    }

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
                pconfig = AuthorizeNetServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.SubscriptionWrapper values = AuthorizeNetServiceHelper.authorizeNetCancelubscription(paymentDetails, pconfig);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;
            at.Subscription__r = new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId);

            System.debug('values==>' + values);
            String responseMessage = '';

            if(values.messages != null && !values.messages.message.isempty()){
                for(ManagePaymentDTOService.cls_message message : values.messages.message){
                    responseMessage += 'Code = ' + message.code + ' :: Description = ' + message.text + ' \n';
                }
            }


            responseMessage += '\n';


            if(values.messages.resultCode == 'Ok' && values.messages.message[0].code == 'I00001'){
                ctrObj.success = true;
                upsert (new Subscription__c(Subscription_Id__c = paymentDetails.otherdetails.subscriptionId, Status__c = 'InActive')) Subscription_Id__c;

            }else{
                ctrObj.success = false;
                ctrObj.responseText = responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){

                insert at;
            }

        }
        return ctrObj;
    }




    @AuraEnabled
    public static ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.SubscriptionTransactionResponse ctrObj = new ManagePaymentDTOService.SubscriptionTransactionResponse();

        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        ManagePaymentDTOService.cls_transactionRequest tr = new ManagePaymentDTOService.cls_transactionRequest();
        return AuthorizeNetServiceHelper.authorizeNetGetSubscriptions(paymentDetails);

    }

    @AuraEnabled
    public static ManagePaymentDTOService.PaymentData retrieveRecord(Id recordId, String sobjectAPIName, String paymentserviceprovider){


        Payment_Configuration__c pconfig = AuthorizeNetServiceHelper.getPaymentConfig(sobjectAPIName, paymentserviceprovider); 
        String select1 = 'select ';
        String query =  (pconfig.Address_API_Name__c != null ? pconfig.Address_API_Name__c +',' : '');
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

        Set<String> tmpSet = New Set<String>(query.split(','));
        query = string.join(New List<String>(tmpSet),',');

        query = select1 + query.removeEnd(',');
        query += ' from '+ sobjectAPIName +' where id =: recordId';

        System.debug('query====>' + query);
        SObject record = Database.query(query);
        ManagePaymentDTOService.PaymentData pdObj = new ManagePaymentDTOService.PaymentData();
        pdObj.amount = pconfig.Amount_API_Name__c != null ? (Decimal)record.get(pconfig.Amount_API_Name__c) : 0;
        pdobj.street = pconfig.Address_API_Name__c != null ? (String)record.get(pconfig.Address_API_Name__c) : '';
        pdobj.city = pconfig.City_API_Name__c != null ? (String)record.get(pconfig.City_API_Name__c) : '';
        //pdobj.street2 = (String)record.get(pconfig.Amount_API_Name__c);
        pdobj.state =  pconfig.State_API_Name__c != null ? (String)record.get(pconfig.State_API_Name__c) : '';
        pdobj.zip = pconfig.Zip_API_Name__c != null ? (String)record.get(pconfig.Zip_API_Name__c) : '';
        pdobj.country = pconfig.Country_API_Name__c != null ? (String)record.get(pconfig.Country_API_Name__c) : '';
        pdobj.email = pconfig.Email_API_Name__c != null ? (String)record.get(pconfig.Email_API_Name__c) : '';
        pdobj.firstname =  pconfig.First_Name_API_Name__c != null ? (String)record.get(pconfig.First_Name_API_Name__c) : '';
        pdobj.lastname = pconfig.Last_Name_API_Name__c != null ? (String)record.get(pconfig.Last_Name_API_Name__c) : '';
        pdobj.product = pconfig.Product_API_Name__c != null ? (String)record.get(pconfig.Product_API_Name__c) : '';
        pdobj.objectapiname = pconfig.Object_Api_Name__c;
        pdobj.fieldapiname = pconfig.SObject_Payment_Lookup_API_Name__c;
        
        pdobj.refId = pconfig.RefId_Api_Name__c != null ? (String)record.get(pconfig.RefId_Api_Name__c) : '';
        pdobj.company = pconfig.Company_API_Name__c != null ? (String)record.get(pconfig.Company_API_Name__c) : '';
        pdobj.customerid = pconfig.Customer_Id_API_Name__c != null ? (String)record.get(pconfig.Customer_Id_API_Name__c) : '';
        pdobj.externalPaymentURL = pconfig.Community_URL__c + '';

        pdobj.externalPaymentURL = pconfig.Community_URL__c;

        pdobj.externalPaymentURL += '?amount=' + (pconfig.Amount_API_Name__c != null ? (Decimal)record.get(pconfig.Amount_API_Name__c) : 0);
        pdobj.externalPaymentURL += '&street=' + (pconfig.Address_API_Name__c != null ? (String)record.get(pconfig.Address_API_Name__c) : '');
        pdobj.externalPaymentURL += '&city=' + (pconfig.City_API_Name__c != null ? (String)record.get(pconfig.City_API_Name__c) : '');
        pdobj.externalPaymentURL += '&state=' + (pconfig.State_API_Name__c != null ? (String)record.get(pconfig.State_API_Name__c) : '');
        pdobj.externalPaymentURL += '&zip=' + (pconfig.Zip_API_Name__c != null ? (String)record.get(pconfig.Zip_API_Name__c) : '');
        pdobj.externalPaymentURL += '&country=' + (pconfig.Country_API_Name__c != null ? (String)record.get(pconfig.Country_API_Name__c) : '');
        pdobj.externalPaymentURL += '&email=' + (pconfig.Email_API_Name__c != null ? (String)record.get(pconfig.Email_API_Name__c) : '');
        pdobj.externalPaymentURL += '&firstname=' + (pconfig.First_Name_API_Name__c != null ? (String)record.get(pconfig.First_Name_API_Name__c) : '');
        pdobj.externalPaymentURL += '&lastname=' + (pconfig.Last_Name_API_Name__c != null ? (String)record.get(pconfig.Last_Name_API_Name__c) : '');
        pdobj.externalPaymentURL += '&product=' + (pconfig.Product_API_Name__c != null ? (String)record.get(pconfig.Product_API_Name__c) : '');
        pdobj.externalPaymentURL += '&objectapiname=' + (pconfig.Object_Api_Name__c);
        pdobj.externalPaymentURL += '&fieldapiname=' + (pconfig.SObject_Payment_Lookup_API_Name__c);
        pdobj.externalPaymentURL += '&refid=' +  (pconfig.RefId_Api_Name__c != null ? (String)record.get(pconfig.RefId_Api_Name__c) : '');
        pdobj.externalPaymentURL += '&company=' + (pconfig.Company_API_Name__c != null ? (String)record.get(pconfig.Company_API_Name__c) : '');
        pdobj.externalPaymentURL += '&customerid=' + (pconfig.Customer_Id_API_Name__c != null ? (String)record.get(pconfig.Customer_Id_API_Name__c) : '');


        
        return pdobj;

    }

    public static void processWebhook(String requestbody){
        AuthorizeNetServiceHelper.authorizeNetProcessWebhook(requestbody);
    }
    
}