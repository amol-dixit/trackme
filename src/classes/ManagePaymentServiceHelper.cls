public without sharing class ManagePaymentServiceHelper {
    public static void handleInsertDML(SObject sobj){
        insert sobj;
    }
    public static void handleUpsertDML(List<SObject> sobjList){
        upsert sobjList;
    }

    public static PaymentServiceInterface getPaymentServiceInstance(String paymentserviceprovider){
        Type gatewayType = Type.forName(paymentserviceprovider + 'ServiceHelper');
        if(gatewayType == null) {
            String[] errorMsg = new String[] {
                paymentserviceprovider + '" is not supported '
            };
            //throw new Merchant.UnsupportedGatewayException(String.join(errorMsg, ' '));
        }
        return (PaymentServiceInterface)gatewayType.newInstance();
    
    }
    static Payment_Configuration__c pconfig;
    public static Payment_Configuration__c getPaymentConfig(String objectApiName, String paymentserviceprovider) {
        if(pconfig == null){

            List<Payment_Configuration__c> pconfiglist = [select Expiration_Days__c, Enable_Encrypted_Payment_URL__c, Encryption_Key__c, Secret_Key__c,Sub_Header_API_Name__c, Custom_1__c, Custom_2__c, Custom_3__c, Custom_4__c, External_Payment_URL__c, Community_URL__c, Enable_Logging__c, Auth_API_Login_Id__c, Endpoint_URL__c, Auth_Transaction_Key__c, 
            SObject_Payment_Lookup_API_Name__c, Object_Api_Name__c, Address_API_Name__c, Amount_API_Name__c,
            City_API_Name__c,Company_API_Name__c, Country_API_Name__c, Customer_Id_API_Name__c, Email_API_Name__c,First_Name_API_Name__c, Last_Name_API_Name__c,
                Product_API_Name__c, RefId_Api_Name__c, Return_URL__c,Return_URL_API_Name__c, State_API_Name__c, Zip_API_Name__c from Payment_Configuration__c where name = :paymentserviceprovider AND Object_Api_Name__c =: objectApiName];
            if(pconfiglist == null || pconfiglist.size() == 0 ){
                throw new ManagePaymentService.PaymentException('Payment Service Provider details have not configured, please contact your system admnistrator for more details.');
            }
            pconfig = pconfiglist[0];
        }
        return pconfig;
    }

    public static boolean validatePayment(String transacationKey){
        if([select count() from Payment__c where Transaction_Key__c =: transacationKey] > 0){
            return true;
        }
        return false;
    }

}