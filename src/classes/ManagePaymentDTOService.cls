/**
 * This class provides all the DTO wrapper methods to accept/process/return the data.
 * 
 */
public with sharing class ManagePaymentDTOService {

    public class cls_getTransactionDetailsResponse {
        public cls_transaction transaction1;
        public Transaction_messages messages;

    }
        public class PaymentDetails{
            public AddressDetails addressdetails;
            public CardDetails carddetails;
            public BankDetails bankdetails;
            public OtherDetails otherDetails;
            public SubDetails subDetails;
            public Boolean serviceChargeTransaction = false;
            public PaymentDetails(){
                this.serviceChargeTransaction  = false;
            }
        }

        public class TransactionResponse{
            @AuraEnabled
            public Boolean success;
            @AuraEnabled
            public String message;
        }

        public class OtherDetails{
            public String product;
            public Decimal amount;
            public String refid;
            public String fieldapiname;
            public String company;
            public String customerid;
            public String objectapiname;
            //public String subId;
            public String subscriptionId;
            public String trackPaySubscriptionId;
            public String paymentserviceprovider;
            public String custom1;
            public String custom2;
            public String custom3;
            public String custom4;
            public String transactionkey;

        }
        
        public class SubDetails{
            public String occurrances;
            public String unit;
            public String subname;
            public String subscriptionname;
            public String startdate;
            public Decimal amount;
            public Decimal serviceCharge;
        }
        public class BankDetails{
            public String accountType;
            public String routingNumber;
            public String accountNumber;
            public String nameOnAccount;
        }

        public class AddressDetails{
            public String firstName;
            public String lastName;
            public String BillingCountry;
            public String BillingStreet;
            public String BillingStreet2;
            public String BillingCity;
            public String BillingPostalCode;
            public String BillingState;
        }

        public class CardDetails{
            public String cardNumber;
            //public String cardHolderName;
            public String cardHolderFirstName;
            public String cardHolderLastName;
            public String cardCVV;
            public String cardExpiry;
            public String cardType;
            public String cardEmail;
            
        }

        public class TransactionRequestWrapper{
            public cls_createTransactionRequest createTransactionRequest;
        }

        public class cls_createTransactionRequest {
            public cls_merchantAuthentication merchantAuthentication;
            public String refId;
            public cls_transactionRequest transactionRequest;
        }
        public class cls_merchantAuthentication {
            public String name;
            public String transactionKey;
        }
        public class cls_transactionRequest {
            public String transactionType;
            public String amount;
            public cls_payment payment;
            public cls_lineItems lineItems;
            public cls_tax tax;
            public cls_duty duty;
            public cls_shipping shipping;
            public String poNumber;
            public cls_customer customer;
            public cls_billTo billTo;
            public cls_shipTo shipTo;
            public String customerIP;
            public cls_transactionSettings transactionSettings;
            public cls_userFields userFields;
            public cls_processingOptions processingOptions;
            public cls_subsequentAuthInformation subsequentAuthInformation;
            public cls_authorizationIndicatorType authorizationIndicatorType;
        }
        public class cls_payment {
            public cls_creditCard creditCard;
        }
        public class cls_creditCard {
            public String cardNumber;
            public String expirationDate;
            public String cardCode;
            public String cardType;
        }
        public class cls_lineItems {
            public cls_lineItem lineItem;
        }
        public class cls_lineItem {
            public String itemId;
            public String name;
            public String description;
            public String quantity;
            public String unitPrice;
        }
        public class cls_tax {
            public String amount;
            public String name;
            public String description;
        }
        public class cls_duty {
            public String amount;
            public String name;
            public String description;
        }
        public class cls_shipping {
            public String amount;
            public String name;
            public String description;
        }
        public class cls_customer {
            public String id;
        }
        public class cls_billTo {
            public String firstName;
            public String lastName;
            public String company;
            public String address;
            public String city;
            public String state;
            public String zip;
            public String country;
            public String phoneNumber;

        }
        public class cls_shipTo {
            public String firstName;
            public String lastName;
            public String company;
            public String address;
            public String city;
            public String state;
            public String zip;
            public String country;
        }
        public class cls_transactionSettings {
            public cls_setting setting;
        }
        public class cls_setting {
            public String settingName;
            public String settingValue;
        }
        public class cls_userFields {
            public cls_userField[] userField;
        }
        public class cls_userField {
            public String name;
            public String value;
        }
        public class cls_processingOptions {
            public String isSubsequentAuth;
        }
        public class cls_subsequentAuthInformation {
            public String originalNetworkTransId;
            public String originalAuthAmount;
            public String reason;
        }
        public class cls_authorizationIndicatorType {
            public String authorizationIndicator;
        }

        public class cls_profile {
            public String customerProfileId;
            public String customerPaymentProfileId;
        }

        public class Transaction_Reponse_Wrapper{
            public String requestString;
            public String responseString;
            public Integer statusCode;
            public Boolean issuccess;
            public String refId;
            public String transId;
            public String authCode;
            public String accountNumber;
            public String accountType;
            public String responseMessage;
            public String resultCode;
            public Decimal amount;
            public String trackpayTransactionId;
            public Decimal serviceFee;
            public String cardServicesResponse;
            public String trackPayRequestString;
            public String trackPayResponseString;
            public String trackPayResponseMessage;
            public Integer trackPaystatusCode;
        }

        public class Auth_Transaction_Reponse_Wrapper{
            public cls_transactionResponse transactionResponse;
            public String refId;
            public Transaction_messages messages;
        }
    
        public class Sub_Reponse_Wrapper{
            public String requestString;
            public String responseString;
            public String responseMessage;
            public Integer statusCode;

            public String trackPayRequestString;
            public String trackPayResponseString;
            public String trackPayResponseMessage;
            public Integer trackPaystatusCode;

            public String refId;
            public String subscriptionId;
            public String trackPaySubscriptionId;
            public cls_profile profile;
            public String cardServicesResponse;
            public Transaction_messages messages;
            public Boolean issuccess;
            public Decimal amount;
            public Decimal serviceCharge;
        }

        public class Transaction_messages{
            public String resultCode;
            public List<cls_message> message;
        }
    
        public class Transaction_response_messages{
            public String code;
            public String description;
        }

        public class cls_messages {
            public String resultCode;
            public cls_message message;
        }
        public class cls_message {
            public String code;
            public String text;
            public String description;
            
        }

        public class cls_transactionResponse {
            public String responseCode;
            public String responseMessage;
            public String authCode;
            public String transId;
            public String refTransID;
            public String transHash;
            public String testRequest;
            public String accountNumber;
            public String accountType;
            public cls_error[] errors;
            public Transaction_response_messages[] messages;
            public String transHashSha2;
            public Integer SupplementalDataQualificationIndicator;
        }
        public class cls_error {
            public String errorCode;    //1806660050
            public String errorText; //1805324550
        }

        public class ChargeTransactionResponse{
            @AuraEnabled
            public Boolean success;
            @AuraEnabled
            public String responseText;
            @AuraEnabled
            public String authCode;
            @AuraEnabled
            public String transactionId;
            @AuraEnabled
            public String accountNumber;
            @AuraEnabled
            public String accountType;
            @AuraEnabled
            public String address;
            @AuraEnabled
            public String city;
            @AuraEnabled
            public String state;
            @AuraEnabled
            public String zip;
            @AuraEnabled
            public String country;
            @AuraEnabled
            public Payment__c paymentObj;
        }
        
        public class SubscriptionTransactionResponse{
            @AuraEnabled
            public Boolean success;
            @AuraEnabled
            public String responseText;
            @AuraEnabled
            public String authCode;
            @AuraEnabled
            public Subscription__c subObj;

            @AuraEnabled
            public Date startDate;
            @AuraEnabled
            public String subId;
            @AuraEnabled
            public String unit;
            @AuraEnabled
            public Decimal occurance;
            @AuraEnabled
            public String length;
        }

        public class Refund_Reponse_Wrapper{
            public cls_transactionResponse transactionResponse;
            public String refId;
            public Transaction_messages messages;
        }
    
        public class PaymentData{
            @AuraEnabled
            public Decimal amount;
            @AuraEnabled
            public String street;
            @AuraEnabled
            public String city;
            @AuraEnabled
            public String street2;
            @AuraEnabled
            public String state;
            @AuraEnabled
            public String zip;
            @AuraEnabled
            public String country;
            @AuraEnabled
            public String email;
            @AuraEnabled
            public String firstname;
            @AuraEnabled
            public String lastname;
            @AuraEnabled
            public String product;
            @AuraEnabled
            public String fieldapiname;
            @AuraEnabled
            public String refid;
            @AuraEnabled
            public String company;
            @AuraEnabled
            public String customerid;
            @AuraEnabled
            public String objectapiname;
            @AuraEnabled
            public String externalPaymentURL;
            @AuraEnabled
            public String externalPaymentEncryptedURL;
            @AuraEnabled
            public String custom1;
            @AuraEnabled
            public String custom2;
            @AuraEnabled
            public String custom3;
            @AuraEnabled
            public String custom4;
            @AuraEnabled
            public String subheader;
            
            @AuraEnabled
            public String returl;

            @AuraEnabled
            public String transactionkey;
            
            @AuraEnabled
            public Boolean enableencrption;

        }
        public class SubscriptionWrapper{
            public String requestString;
            public String responseString;
            public Integer statusCode;
            public Boolean issuccess;
            @AuraEnabled public Integer totalNumInResultSet;
            @AuraEnabled public cls_subscriptionDetails[] subscriptionDetails;
            @AuraEnabled public String refId;
            @AuraEnabled public Transaction_messages messages;

        }

        public class cls_subscriptionDetails {
            @AuraEnabled
            public Integer id;
            @AuraEnabled public String name;
            @AuraEnabled public String status;
            @AuraEnabled public String createTimeStampUTC;
            @AuraEnabled  public String firstName;
            @AuraEnabled public String lastName;
            @AuraEnabled public Integer totalOccurrences;
            @AuraEnabled public String trackPaySubscriptionId;
            @AuraEnabled public Integer pastOccurrences;
            @AuraEnabled public String paymentMethod;
            @AuraEnabled public String accountNumber;
            @AuraEnabled public String invoice;
            @AuraEnabled public Decimal amount;
            @AuraEnabled public String currencyCode;
            @AuraEnabled public Integer customerProfileId;
            @AuraEnabled public Integer customerPaymentProfileId;
        }
    
        public class cls_transaction {
            public String transId;
            public String refTransId;
            public String splitTenderId; 
            public String submitTimeUTC; 
            public String submitTimeLocal;
            public String transactionType;
            public String transactionStatus; 
            public String responseCode;
            public String responseReasonCode;
            public String responseReasonDescription;
            public String authCode;
            public String AVSResponse;
            public String cardCodeResponse;
            public String CAVVResponse;
            public String FDSFilterAction;
            public cls_batch batch;
            public cls_order order;
            public String requestedAmount;
            public String authAmount;
            public String settleAmount;
            public cls_tax tax;
            public cls_shipping shipping;
            public cls_duty duty;
            public cls_lineItems lineItems;
            public String prepaidBalanceRemaining;
            public String taxExempt;
            public cls_payment payment;
            public cls_customer customer;
            public cls_billTo billTo;
            public cls_shipTo shipTo;
            public String recurringBilling;
            public String customerIP;
            public cls_subscription subscription;
            public cls_profile profile;
            public String networkTransId;
            public String originalNetworkTransId;
            public String originalAuthAmount;
            public String authorizationIndicator;

        }
        public class cls_batch {
            public String batchId;
            public String settlementTimeUTC;
            public String settlementTimeLocal;
            public String settlementState;
        }
        public class cls_order {
            public String invoiceNumber;
            public String description;
            public String purchaseOrderNumber;
        }
        public class cls_subscription {
            public String id;
            public Decimal payNum;
            public String marketType;
            public String product;
            public cls_returnedItems returnedItems;
            public cls_solution solution;
            public String mobileDeviceId;
        }
        public class cls_returnedItems {
            public cls_returnedItem returnedItem;
        }
        public class cls_returnedItem {
            public String id;
            public String dateUTC;
            public String dateLocal;
            public String code;
            public String description;
        }
        public class cls_solution {
            public String id;
            public String name;
            public String vendorName;
        }
        public class Notification{
            public Payload payload;
            public String eventType;
            
        }
        public class Payload{
            public String id;
            public String merchantReferenceId;
            public Decimal authAmount;
        }
    
}