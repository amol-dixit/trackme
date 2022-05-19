public interface PaymentServiceInterface {
    ManagePaymentDTOService.Transaction_Reponse_Wrapper chargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails);
    List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> refundTransaction(List<Payment__c> paymentObj);
    List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> voidTransaction(List<Payment__c> paymentList);
    ManagePaymentDTOService.Sub_Reponse_Wrapper createSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.Sub_Reponse_Wrapper updateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.Sub_Reponse_Wrapper cancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(ManagePaymentDTOService.PaymentDetails paymentDetails);
}