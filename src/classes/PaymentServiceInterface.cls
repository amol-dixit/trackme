public interface PaymentServiceInterface {
    ManagePaymentDTOService.Transaction_Reponse_Wrapper chargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.Transaction_Reponse_Wrapper refundTransaction(Payment__c paymentObj);
    ManagePaymentDTOService.Transaction_Reponse_Wrapper voidTransaction(Payment__c paymentObj);
    ManagePaymentDTOService.Sub_Reponse_Wrapper createSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.Sub_Reponse_Wrapper updateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.SubscriptionWrapper cancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails);
    ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(ManagePaymentDTOService.PaymentDetails paymentDetails);
}