/**
 * This class is reponsible to provide helper methods to ManagePaymentService
 * 
 */
public without sharing class ManagePaymentServiceHelper {
    // It does the insert DML operation in without sharing context.
    public static void handleInsertDML(List<SObject> sobjList){
        SObjectType objType = sobjList[0].getSObjectType();
        if (objType.getDescribe().isCreateable() ) {
            insert sobjList;
        }
    }

    // It does the upsert DML operation in without sharing context.
    public static void handleUpsertDML(List<SObject> sobjList){
        SObjectType objType = sobjList[0].getSObjectType();
        if (objType.getDescribe().isCreateable() && objType.getDescribe().isUpdateable()) {
            upsert sobjList;
        }
    }

    // This method returns the Payment Service instance dynamically. 
    public static PaymentServiceInterface getPaymentServiceInstance(String paymentserviceprovider){
        Type gatewayType = Type.forName(paymentserviceprovider + 'Service');
        if(gatewayType == null) {
            String[] errorMsg = new String[] {
                paymentserviceprovider + '" is not supported '
            };
        }
        return (PaymentServiceInterface)gatewayType.newInstance();
    
    }
    static Payment_Configuration__c pconfig;
    // This method fetches the Payment config custom metadata for a specific object and Service Provider
    public static Payment_Configuration__c getPaymentConfig(String objectApiName, String paymentserviceprovider) {
        if(pconfig == null || pconfig.name != paymentserviceprovider){
            String query = 'select Name, Refund_Amount_API_Name__c, Auth_License_Key__c, Expiration_Days__c, Enable_Encrypted_Payment_URL__c, Encryption_Key__c, Secret_Key__c,Sub_Header_API_Name__c, Custom_1__c, Custom_2__c, Custom_3__c, Custom_4__c, External_Payment_URL__c, Community_URL__c, Enable_Logging__c, Auth_API_Login_Id__c, Endpoint_URL__c, Auth_Transaction_Key__c, '
            + ' SObject_Payment_Lookup_API_Name__c, Object_Api_Name__c, Address_API_Name__c, Amount_API_Name__c, '
            + ' City_API_Name__c,Company_API_Name__c, Country_API_Name__c, Customer_Id_API_Name__c, Email_API_Name__c,First_Name_API_Name__c, Last_Name_API_Name__c,'
            + '     Product_API_Name__c, RefId_Api_Name__c, Return_URL__c,Return_URL_API_Name__c, State_API_Name__c, Zip_API_Name__c from Payment_Configuration__c where name = :paymentserviceprovider ';
            if(objectApiName != null){
                query += ' AND Object_Api_Name__c =: objectApiName ';
            }
            List<Payment_Configuration__c> pconfiglist = Database.query(query);
            if(pconfiglist == null || pconfiglist.size() == 0 ){
                throw new ManagePaymentService.PaymentException('Payment Service Provider details have not configured, please contact your system admnistrator for more details.');
            }
            if(pconfiglist[0].Auth_License_Key__c == null){
                throw new ManagePaymentService.PaymentException('Licence Key is required, please contact your system admnistrator for more details.');
            }
            pconfig = pconfiglist[0];
        }
        return pconfig;
    }

    // This method is responsible to validate the Payment link based on the transaction id present or not.
    public static boolean validatePayment(String transacationKey){
        if([select count() from Payment__c where Transaction_Key__c =: transacationKey] > 0){
            return true;
        }
        return false;
    }

}