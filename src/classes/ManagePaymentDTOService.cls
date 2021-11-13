public without sharing class ManagePaymentDTOService {

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
            public String paymentserviceprovider;


        }
        
        public class SubDetails{
            public String occurrances;
            public String unit;
            public String subname;
            public String subscriptionname;
            public String startdate;
            public Decimal amount;
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
            public String refId;	//123456
            public cls_transactionRequest transactionRequest;
        }
        public class cls_merchantAuthentication {
            public String name;	//3etUv5PvB24
            public String transactionKey;	//9LVfY7446vGJ66qK
        }
        public class cls_transactionRequest {
            public String transactionType;	//authCaptureTransaction
            public String amount;	//5
            public cls_payment payment;
            public cls_lineItems lineItems;
            public cls_tax tax;
            public cls_duty duty;
            public cls_shipping shipping;
            public String poNumber;	//456654
            public cls_customer customer;
            public cls_billTo billTo;
            public cls_shipTo shipTo;
            public String customerIP;	//192.168.1.1
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
            public String cardNumber;	//5424000000000015
            public String expirationDate;	//2025-12
            public String cardCode;	//999
            public String cardType; //Visa
        }
        public class cls_lineItems {
            public cls_lineItem lineItem;
        }
        public class cls_lineItem {
            public String itemId;	//1
            public String name;	//vase
            public String description;	//Cannes logo
            public String quantity;	//18
            public String unitPrice;	//45.00
        }
        public class cls_tax {
            public String amount;	//4.26
            public String name;	//level2 tax name
            public String description;	//level2 tax
        }
        public class cls_duty {
            public String amount;	//8.55
            public String name;	//duty name
            public String description;	//duty description
        }
        public class cls_shipping {
            public String amount;	//4.26
            public String name;	//level2 tax name
            public String description;	//level2 tax
        }
        public class cls_customer {
            public String id;	//99999456654
        }
        public class cls_billTo {
            public String firstName;	//Ellen
            public String lastName;	//Johnson
            public String company;	//Souveniropolis
            public String address;	//14 Main Street
            public String city;	//Pecan Springs
            public String state;	//TX
            public String zip;	//44628
            public String country;	//US
            public String phoneNumber;  //000-000-0000

        }
        public class cls_shipTo {
            public String firstName;	//China
            public String lastName;	//Bayles
            public String company;	//Thyme for Tea
            public String address;	//12 Main Street
            public String city;	//Pecan Springs
            public String state;	//TX
            public String zip;	//44628
            public String country;	//US
        }
        public class cls_transactionSettings {
            public cls_setting setting;
        }
        public class cls_setting {
            public String settingName;	//testRequest
            public String settingValue;	//false
        }
        public class cls_userFields {
            public cls_userField[] userField;
        }
        public class cls_userField {
            public String name;	//MerchantDefinedFieldName1
            public String value;	//MerchantDefinedFieldValue1
        }
        public class cls_processingOptions {
            public String isSubsequentAuth;	//true
        }
        public class cls_subsequentAuthInformation {
            public String originalNetworkTransId;	//123456789NNNH
            public String originalAuthAmount;	//45.00
            public String reason;	//resubmission
        }
        public class cls_authorizationIndicatorType {
            public String authorizationIndicator;	//final
        }

        public class cls_profile {
            public String customerProfileId;	//123456789NNNH
            public String customerPaymentProfileId;	//45.00
        }

        public class Transaction_Reponse_Wrapper{
            public String requestString;
            public String responseString;
            public Integer statusCode;
            public cls_transactionResponse transactionResponse;
            public String refId;
            public Transaction_messages messages;
        }
    
        public class Sub_Reponse_Wrapper{
            public String requestString;
            public String responseString;
            public Integer statusCode;

            public String refId;
            public String subscriptionId;
            public cls_profile profile;

            public Transaction_messages messages;
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
            public String resultCode;   //Ok
            public cls_message message;
        }
        public class cls_message {
            public String code; //I00001
            public String text; //Successful.
        }

        public class cls_transactionResponse {
            public String responseCode;	//1
            public String authCode;	//
            public String avsResultCode;	//P
            public String cvvResultCode;	//
            public String cavvResultCode;	//
            public String transId;	//40067222795
            public String refTransID;	//40065051483
            public String transHash;	//
            public String testRequest;	//0
            public String accountNumber;	//XXXX0027
            public String accountType;	//Visa
            public cls_error[] errors;
            public Transaction_response_messages[] messages;
            
            public String transHashSha2;	//4261FA94C7DE2BA95275EF49C75F845D4BD3E67F9115133C46607A890440124FD7C4DCE820E79C706C969ECBF51E7464A3CBF64712F2D69DFFC2ECFE7E9A0898
            public Integer SupplementalDataQualificationIndicator;	//0
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

        }
        public class SubscriptionWrapper{
            public String requestString;
            public String responseString;
            public Integer statusCode;

            @AuraEnabled public Integer totalNumInResultSet;	//36391
            @AuraEnabled public cls_subscriptionDetails[] subscriptionDetails;
            @AuraEnabled public String refId;
            @AuraEnabled public Transaction_messages messages;

        }

        public class cls_subscriptionDetails {
            @AuraEnabled
            public Integer id;	//5517459
            @AuraEnabled public String name;	//Sample Subscription
            @AuraEnabled public String status;	//active
            @AuraEnabled public String createTimeStampUTC;	//2018-12-27T07:35:22.43
            @AuraEnabled  public String firstName;	//John
            @AuraEnabled public String lastName;	//Smith
            @AuraEnabled public Integer totalOccurrences;	//12
            @AuraEnabled public Integer pastOccurrences;	//11
            @AuraEnabled public String paymentMethod;	//creditCard
            @AuraEnabled public String accountNumber;	//XXXX1111
            @AuraEnabled public String invoice;	//
            @AuraEnabled public Decimal amount;	//3972
            @AuraEnabled public String currencyCode;	//USD
            @AuraEnabled public Integer customerProfileId;	//1506300582
            @AuraEnabled public Integer customerPaymentProfileId;	//1505644064
        }
    
        public class cls_transaction {
            public String transId;  //12345
            public String refTransId;   //12345
            public String splitTenderId;    //12345
            public String submitTimeUTC;    //2010-08-30T17:49:20.757Z
            public String submitTimeLocal;  //2010-08-30T13:49:20.757
            public String transactionType;  //authOnlyTransaction
            public String transactionStatus;    //settledSuccessfully
            public String responseCode; //1
            public String responseReasonCode;   //1
            public String responseReasonDescription;    //Approval
            public String authCode; //000000
            public String AVSResponse;  //X
            public String cardCodeResponse; //M
            public String CAVVResponse; //2
            public String FDSFilterAction;  //authAndHold
            //public cls_FDSFilters FDSFilters;
            public cls_batch batch;
            public cls_order order;
            public String requestedAmount;  //5.00
            public String authAmount;   //2.00
            public String settleAmount; //2.00
            public cls_tax tax;
            public cls_shipping shipping;
            public cls_duty duty;
            public cls_lineItems lineItems;
            public String prepaidBalanceRemaining;  //30.00
            public String taxExempt;    //false
            public cls_payment payment;
            public cls_customer customer;
            public cls_billTo billTo;
            public cls_shipTo shipTo;
            public String recurringBilling; //false
            public String customerIP;   //0.0.0.0
            public cls_subscription subscription;
            public cls_profile profile;
            public String networkTransId;   //123456789KLNLN9H
            public String originalNetworkTransId;   //123456789NNNH
            public String originalAuthAmount;   //12.00
            public String authorizationIndicator;   //pre

        }
        public class cls_batch {
            public String batchId;  //12345
            public String settlementTimeUTC;    //2010-08-30T17:49:20.757Z
            public String settlementTimeLocal;  //2010-08-30T13:49:20.757
            public String settlementState;  //settledSuccessfully
        }
        public class cls_order {
            public String invoiceNumber;    //INV00001
            public String description;  //some description
            public String purchaseOrderNumber;  //PO000001
        }
        public class cls_subscription {
            public String id;   //145521
            public Decimal payNum;   //1
            public String marketType;   //eCommerce
            public String product;  //Card Not Present
            public cls_returnedItems returnedItems;
            public cls_solution solution;
            public String mobileDeviceId;   //2354578983274523978
        }
        public class cls_returnedItems {
            public cls_returnedItem returnedItem;
        }
        public class cls_returnedItem {
            public String id;   //2148878904
            public String dateUTC;  //2014-05-12T21:22:44Z
            public String dateLocal;    //2014-05-12T14:22:44
            public String code; //R02
            public String description;  //Account Closed
        }
        public class cls_solution {
            public String id;   //A1000004
            public String name; //Shopping Cart
            public String vendorName;   //WidgetCo
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