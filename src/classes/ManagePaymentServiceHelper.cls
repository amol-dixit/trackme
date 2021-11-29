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


}