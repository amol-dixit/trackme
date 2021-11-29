global with sharing class ManagePaymentService {
    @AuraEnabled
    public static ManagePaymentDTOService.ChargeTransactionResponse chargeTransaction(String paymentData){
        System.debug('paymentData' + paymentData);
        ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
        ManagePaymentDTOService.PaymentDetails paymentDetails = (ManagePaymentDTOService.PaymentDetails) System.JSON.deserialize(paymentData, ManagePaymentDTOService.PaymentDetails.class);
        Payment_Configuration__c pconfig;
        ManagePaymentDTOService.Transaction_Reponse_Wrapper values;
        if(paymentDetails.otherDetails.paymentserviceprovider == null || paymentDetails.otherDetails.paymentserviceprovider == ''){
            throw new AuthorizeNetServiceHelper.PaymentException('Payment Service Provider is not configured. Please contact system administrator.');
        }

        API_Tracker__c at = new API_Tracker__c();

        try{
            values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).chargeTransaction(paymentDetails);

            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;
            System.debug('values==>' + values);

            if(values.issuccess){
                ctrObj.success = true;
                ctrObj.authCode = values.authCode;
                ctrObj.transactionId = values.transId;
                ctrObj.accountNumber = values.accountNumber;
                ctrObj.accountType = values.accountType;

                Payment__c paymentObj = new Payment__c();
                paymentObj.Amount__c = paymentDetails.otherdetails.amount;
                paymentObj.put(paymentDetails.otherdetails.fieldapiname, paymentDetails.otherdetails.refId);
                paymentObj.SObect_API_Name__c = paymentDetails.otherdetails.objectapiname;
                paymentObj.Transaction_Id__c = ctrObj.transactionId;
                paymentObj.Source__c = paymentDetails.otherDetails.paymentserviceprovider;
                paymentObj.Payment_Date__c = System.today();
                paymentObj.Email__c = paymentDetails.carddetails.cardEmail;
                paymentObj.RecordtypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Individual Payment').getRecordTypeId();

                paymentObj.Customer_Id__c = paymentDetails.otherdetails.refId;
                paymentObj.Card_Type__c = values.accountType;
                paymentObj.Card_Number__c = values.accountNumber;
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

                ManagePaymentServiceHelper.handleInsertDML(paymentObj);
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
                ctrObj.responseText = values.responseMessage;
            }

        }catch(Exception e){
            ctrObj.success = false;
            ctrObj.responseText = e.getMessage()+ '::'+ e.getStackTraceString();
            at.Error_Message__c = e.getMessage()+ '::'+ e.getStackTraceString();

        }finally{
            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(at);
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
            ManagePaymentDTOService.Transaction_Reponse_Wrapper values;
            pconfig = getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);

            values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentList[0].Source__c.replace('.', '')).refundTransaction(paymentList[0]);

    
            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

			System.debug('values==>' + values);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;
            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
            if(values.issuccess){
                ctrObj.success = true;
                ctrObj.authCode = values.authCode;
                ctrObj.transactionId = values.transId;
                ctrObj.accountNumber = values.accountNumber;
                ctrObj.accountType = values.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = values.responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Refund_Response__c = values.responseMessage, Refund_Result_Code__c = values.resultCode));
                at.Error_Message__c = values.responseMessage;

            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Refund_Response__c = values.responseMessage, Refund_Result_Code__c = values.resultCode, Refunded__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;
                paymentclone.Transaction_Id__c = values.transId;
                paymentclone.Transaction_Status__c = 'Refunded';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Refund_Result_Code__c = values.resultCode;
                paymentclone.Refund_Response__c = values.responseMessage;
                paymentclone.Refunded__c = true;
                upsertPaymentList.add(paymentclone);
            }

            ManagePaymentServiceHelper.handleUpsertDML(upsertPaymentList);


            tr.success = ctrObj.success;
            tr.message = values.responseMessage;


            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(at);
            }


        }
        return tr;

    }


    @AuraEnabled
    public static ManagePaymentDTOService.TransactionResponse voidTransaction(Id paymentId){

        List<Payment__c> paymentList = Database.query('SELECT SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where id =: paymentId');
        ManagePaymentDTOService.TransactionResponse tr = new ManagePaymentDTOService.TransactionResponse();
        tr.message = '';
        if(!paymentList.isempty()){

             Payment_Configuration__c pconfig = getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
             ManagePaymentDTOService.Transaction_Reponse_Wrapper values;
            values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentList[0].Source__c.replace('.', '')).voidTransaction(paymentList[0]);


            API_Tracker__c at = new API_Tracker__c();
            at.Payment__c = paymentList[0].id;

			System.debug('values==>' + values);
            at.Request_Body__c = values.requestString;
            at.Response_Body__c = values.responseString;
            at.Status_Code__c = values.statusCode;

            ManagePaymentDTOService.ChargeTransactionResponse ctrObj = new ManagePaymentDTOService.ChargeTransactionResponse();
            
            if(values.issuccess){
                ctrObj.success = true;
                ctrObj.authCode = values.authCode;
                ctrObj.transactionId = values.transId;
                ctrObj.accountNumber = values.accountNumber;
                ctrObj.accountType = values.accountType;
            }else{
                ctrObj.success = false;
            }
            ctrObj.responseText = values.responseMessage;
            Payment__c originalPaymentObj = new Payment__c();
            List<Payment__c> upsertPaymentList = new List<Payment__c>();
            if(!ctrObj.success){
                upsertPaymentList.add(new Payment__c (id = paymentId, Void_Response__c = values.responseMessage, Void_Result_Code__c = values.resultCode));
            }else{
                upsertPaymentList.add( new Payment__c (id = paymentId, Void_Response__c = values.responseMessage, Void_Result_Code__c = values.resultCode, Voided__c = true));

                Payment__c paymentclone = (Payment__c)paymentList[0].clone(false, false, false, false);
                paymentclone.Amount__c = -paymentclone.Amount__c;
                paymentclone.Transaction_Id__c = values.transId;
                paymentclone.Transaction_Status__c = 'Voided';
                paymentclone.Original_Payment__c = paymentList[0].id;
                paymentclone.Void_Result_Code__c = values.resultCode;
                paymentclone.Void_Response__c = values.responseMessage;
                paymentclone.Voided__c = true;
                upsertPaymentList.add(paymentclone);
            }
            ManagePaymentServiceHelper.handleUpsertDML(upsertPaymentList);
            tr.message = values.responseMessage;
            tr.success = values.issuccess;

            if(pconfig == null || pconfig.Enable_Logging__c){
                ManagePaymentServiceHelper.handleInsertDML(at);
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
            pconfig = getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

            ManagePaymentDTOService.Sub_Reponse_Wrapper values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).createSubscription(paymentDetails);

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
                //insert subscriptionObj;
                ManagePaymentServiceHelper.handleInsertDML(subscriptionObj);
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
                ManagePaymentServiceHelper.handleInsertDML(at);
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
                pconfig = getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.Sub_Reponse_Wrapper values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).updateSubscription(paymentDetails);

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
                ManagePaymentServiceHelper.handleInsertDML(at);
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
                pconfig = getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
            }
    
            ManagePaymentDTOService.SubscriptionWrapper values = ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).cancelSubscription(paymentDetails);

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
                ManagePaymentServiceHelper.handleInsertDML(at);
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
        return ManagePaymentServiceHelper.getPaymentServiceInstance(paymentDetails.otherDetails.paymentserviceprovider.replace('.', '')).getSubscriptions(paymentDetails);
    }

    @AuraEnabled
    public static ManagePaymentDTOService.PaymentData retrieveRecord(Id recordId, String sobjectAPIName, String paymentserviceprovider){

        Payment_Configuration__c pconfig = getPaymentConfig(sobjectAPIName, paymentserviceprovider);
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
        pdobj.email = (String)fetchRecordData(record, pconfig.Email_API_Name__c);
        pdobj.firstname =  (String)fetchRecordData(record, pconfig.First_Name_API_Name__c);
        pdobj.lastname = (String)fetchRecordData(record, pconfig.Last_Name_API_Name__c);
        pdobj.product = (String)fetchRecordData(record, pconfig.Product_API_Name__c);
        pdobj.objectapiname = pconfig.Object_Api_Name__c;
        pdobj.fieldapiname = pconfig.SObject_Payment_Lookup_API_Name__c;
        pdobj.refId = (String)fetchRecordData(record, pconfig.RefId_Api_Name__c);
        pdobj.company = (String)fetchRecordData(record, pconfig.Company_API_Name__c);
        pdobj.customerid = (String)fetchRecordData(record, pconfig.Customer_Id_API_Name__c);
        pdobj.subheader = (String)fetchRecordData(record, pconfig.Sub_Header_API_Name__c);

        //Custom info
        pdobj.custom1 = pconfig.Custom_1__c;
        pdobj.custom2 = pconfig.Custom_2__c;
        pdobj.custom3 = pconfig.Custom_3__c;
        pdobj.custom4 = pconfig.Custom_4__c;

        pdobj.externalPaymentURL = pconfig.Community_URL__c;
        pdobj.externalPaymentURL += '?amount=' + (pdObj.amount != null ? pdObj.amount : 0);
        pdobj.externalPaymentURL += '&street=' + (pdobj.street != null ? pdobj.street : '');
        pdobj.externalPaymentURL += '&city=' + (pdobj.city != null ? pdobj.city : '');
        pdobj.externalPaymentURL += '&state=' + (pdobj.state != null ? pdobj.state : '');
        pdobj.externalPaymentURL += '&zip=' + (pdobj.zip != null ? pdobj.zip : '');
        pdobj.externalPaymentURL += '&country=' + (pdobj.country != null ? pdobj.country : '');
        pdobj.externalPaymentURL += '&email=' + (pdobj.email != null ? pdobj.email : '');
        pdobj.externalPaymentURL += '&firstname=' + (pdobj.firstname != null ? pdobj.firstname : '');
        pdobj.externalPaymentURL += '&lastname=' + (pdobj.lastname != null ? pdobj.lastname : '');
        pdobj.externalPaymentURL += '&product=' + (pdobj.product != null ? pdobj.product : '');
        pdobj.externalPaymentURL += '&objectapiname=' + (pconfig.Object_Api_Name__c);
        pdobj.externalPaymentURL += '&fieldapiname=' + (pconfig.SObject_Payment_Lookup_API_Name__c);
        pdobj.externalPaymentURL += '&refid=' +  (pdobj.refId != null ? pdobj.refId : '');
        pdobj.externalPaymentURL += '&company=' + (pdobj.company != null ? pdobj.company : '');
        pdobj.externalPaymentURL += '&customerid=' + (pconfig.Customer_Id_API_Name__c != null ? pdobj.customerid : '');
        if(!String.isEmpty(pconfig.Custom_1__c)) pdobj.externalPaymentURL += '&custom1=' + pconfig.Custom_1__c;
        if(!String.isEmpty(pconfig.Custom_2__c)) pdobj.externalPaymentURL += '&custom2=' + pconfig.Custom_2__c;
        if(!String.isEmpty(pconfig.Custom_3__c)) pdobj.externalPaymentURL += '&custom3=' + pconfig.Custom_3__c;
        if(!String.isEmpty(pconfig.Custom_4__c)) pdobj.externalPaymentURL += '&custom4=' + pconfig.Custom_4__c;
        if(!String.isEmpty(pconfig.Sub_Header_API_Name__c)) pdobj.externalPaymentURL += '&subheader=' + pdobj.subheader;


        return pdobj;

    }

    public static void processWebhook(String requestbody){
        AuthorizeNetServiceHelper.authorizeNetProcessWebhook(requestbody);
    }
    
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

    static Payment_Configuration__c pconfig;
    public static Payment_Configuration__c getPaymentConfig(String objectApiName, String paymentserviceprovider) {
        if(pconfig == null){

            List<Payment_Configuration__c> pconfiglist = [select Secret_Key__c,Sub_Header_API_Name__c, Custom_1__c, Custom_2__c, Custom_3__c, Custom_4__c, External_Payment_URL__c, Community_URL__c, Enable_Logging__c, Auth_API_Login_Id__c, Endpoint_URL__c, Auth_Transaction_Key__c, 
            SObject_Payment_Lookup_API_Name__c, Object_Api_Name__c, Address_API_Name__c, Amount_API_Name__c,
            City_API_Name__c,Company_API_Name__c, Country_API_Name__c, Customer_Id_API_Name__c, Email_API_Name__c,First_Name_API_Name__c, Last_Name_API_Name__c,
                Product_API_Name__c, RefId_Api_Name__c, Return_URL__c,Return_URL_API_Name__c, State_API_Name__c, Zip_API_Name__c from Payment_Configuration__c where name = :paymentserviceprovider AND Object_Api_Name__c =: objectApiName];
            if(pconfiglist == null || pconfiglist.size() == 0 ){
                throw new PaymentException('Payment Service Provider details have not configured, please contact your system admnistrator for more details.');
            }
            pconfig = pconfiglist[0];
        }
        return pconfig;
    }

    public class PaymentException extends Exception{}

}