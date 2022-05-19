global class PostPaymentProcessingBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts{

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'select Subscription__r.Card_Services_Fee__c, Subscription__r.TrackPay_Subscription_Id__c, Payment_Number__c, Subscription__r.TrackPay_Customer_Profile_Id__c, Subscription__r.TrackPay_Customer_Payment_Profile_Id__c, Subscription__c, Subscription__r.Routing_Number__c, Subscription__r.Account_Number__c, Subscription__r.Name_on_Account__c, Routing_Number__c, Account_Number__c, Name_on_Account__c, Card_Services_Fee__c, TrackPay_Transaction_Id__c, SObect_API_Name__c, Amount__c,Bill_To_Address__c,Bill_To_City__c,Bill_To_Country__c,Bill_To_First_Name__c,Bill_To_Last_Name__c,Bill_To_Phone__c,Bill_To_State__c,Bill_To_Zip__c,Card_Number__c,Card_Type__c,CreatedById,CreatedDate,Customer_Id__c,Email__c,Id,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,Lead__c,Name,Opportunity__c,OwnerId,Payment_Date__c,Refund_Response__c,Refund_Result_Code__c,Ship_To_Address__c,Ship_To_City__c,Ship_To_Country__c,Ship_To_State__c,Ship_To_Zip__c,Source__c,SystemModstamp,Transaction_Id__c,Transaction_Status__c from Payment__c where Subscription__c != null and TrackPay_Transaction_Id__c = null AND Original_Payment__c = null and recordtype.Name = \'Subscription Payment\' and Subscription__r.TrackPay_Subscription_Id__c != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        AuthorizeNetServiceHelper.getTrackPayTransactionDetails(scope);

    }

    global void finish(Database.BatchableContext BC) {

    }

    global void execute(SchedulableContext ctx){
        Database.executeBatch(new PostPaymentProcessingBatch());
        //System.schedule('TrackPayPostPaymentProcessing', '0 0 * * * ?', new PostPaymentProcessingBatch() );  
    }
}