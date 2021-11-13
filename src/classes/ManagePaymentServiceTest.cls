@isTest
private class ManagePaymentServiceTest {
        
        static Opportunity opportunityObj {get;set;}
        static List<Account> accts;
        public static void init(Boolean log){
              accts = new List<Account>();
              Integer numAccts = 3;
              Integer numOppsPerAcct = 3;
              
              for(Integer i=0;i<numAccts;i++) {
                  Account a = new Account(Name='TestAccount', BillingLatitude= 
                  36.8833934000, BillingLongitude=    
                  -76.2246008000);
                  accts.add(a);
              }
              insert accts;
      
              Product2 prod = new Product2(Name = 'Test Product', 
              Family = 'CampusEd', isactive = true);
              insert prod;
              Id pricebookId = Test.getStandardPricebookId();
              update new Pricebook2(id = pricebookId, Name = 'Standard Price Book');
      
              PricebookEntry pbeid = new PricebookEntry(pricebook2id = pricebookId, product2id = prod.id,unitprice=1.0, isActive=true );
              insert pbeid;
    
              opportunityObj = new Opportunity(Name=accts[0].Name + 'Parent Opportunity ',
                              StageName='CONFIRMED',
                              CloseDate=System.today()+20,
                              AccountId=accts[0].Id, Amount =200);
              insert opportunityObj;
              Payment_Configuration__c pconfig = new Payment_Configuration__c();
              if(log)
              pconfig.Enable_Logging__c = true;
              pconfig.Name = 'Authorize.Net';
              pconfig.Object_Api_Name__c = 'Opportunity';
              pconfig.Auth_API_Login_Id__c = 'Auth_API_Login_Id__c';
              pconfig.Auth_Transaction_Key__c = 'Auth_Transaction_Key__c';
              pconfig.Amount_API_Name__c = 'Amount';
              
              insert pconfig;

        }
    
        static testMethod void testChargeTransaction_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeChargeTransactionCardCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Authorize.Net","product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertEquals([ SELECT Amount__c FROM Payment__c ].Amount__c, 223);
        }

        static testMethod void testChargeTransaction_Bank_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeChargeTransactionBankCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"LName","cardHolderFirstName":"FName","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"test@test.com"},"addressdetails":{"BillingCountry":"United States","BillingStreet":"add1","BillingCity":"city","BillingPostalCode":"08990","BillingState":"NY"},"otherdetails":{"product":"testproduct","amount":"22","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity", "paymentserviceprovider":"Authorize.Net"},"bankdetails":{"accountType":"checking","routingNumber":"063100277","accountNumber":"063100277","nameOnAccount":"Test"}}');
            Test.stopTest();
            system.debug('LOG==>' + [ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ]);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertEquals([ SELECT Amount__c FROM Payment__c ].Amount__c, 22);
        }   
    
        static testMethod void testChargeTransaction_Bank_Negative() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeChargeTransactionBankCalloutMockNegative());
            Test.startTest();
            ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"LName","cardHolderFirstName":"FName","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"test@test.com"},"addressdetails":{"BillingCountry":"United States","BillingStreet":"add1","BillingCity":"city","BillingPostalCode":"08990","BillingState":"NY"},"otherdetails":{"product":"testproduct","amount":"22","refid":"0065e000002WY5Q","fieldapiname":"Opportunity__c","objectapiname":"Opportunity", "paymentserviceprovider":"Authorize.Net"},"bankdetails":{"accountType":"checking","routingNumber":"063100277","accountNumber":"063100277","nameOnAccount":"Test"}}');
            Test.stopTest();
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 0);
        }   

        static testMethod void refundTransaction_Positive() {
            init(true);

            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Authorize.Net';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new AuthorizeNetHttpRefundCalloutMock());

            ManagePaymentService.refundTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 2);
            system.assertEquals([ SELECT Refund_Result_Code__c FROM Payment__c where id =: payment.id].Refund_Result_Code__c, 'Ok');
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id =: payment.id].Refunded__c, true);
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id !=: payment.id].Refunded__c, true);
            system.assertEquals([ SELECT Amount__c FROM Payment__c where id !=: payment.id].Amount__c, -30);

        }   

        static testMethod void refundTransaction_Negative() {
            init(true);
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Authorize.Net';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;

            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new AuthorizeNetHttpRefundErrorCalloutMock());

            ManagePaymentService.refundTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertNotEquals([ SELECT Refund_Result_Code__c FROM Payment__c where id =: payment.id].Refund_Result_Code__c, 'Ok');
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id =: payment.id].Refunded__c, false);

        }

        static testMethod void voidTransaction_Positive() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new AuthorizeChargeTransactionCardCalloutMock());
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Authorize.Net","product":"GC5000 series","amount":223,"refid":"0065e000002WY5QAAW","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Authorize.Net';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new AuthorizeNetHttpVoidCalloutMock());

            ManagePaymentService.voidTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 2);
            system.assertEquals([ SELECT Voided__c FROM Payment__c where id =: payment.id].Voided__c, true);
            system.assertEquals([ SELECT Voided__c FROM Payment__c where id !=: payment.id].Voided__c, true);
            system.assertEquals([ SELECT Amount__c FROM Payment__c where id !=: payment.id].Amount__c, -30);

        }

        static testMethod void voidTransaction_Negative() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new AuthorizeChargeTransactionCardCalloutMock());
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Authorize.Net","product":"GC5000 series","amount":223,"refid":"0065e000002WY5QAAW","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            System.debug('response====>' + response);
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Authorize.Net';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';
            
            
            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new AuthorizeNetHttpVoidErrorCalloutMock());

            ManagePaymentService.voidTransaction(payment.id);
            Test.stopTest();
    
            //system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            //system.assertEquals([ SELECT Voided__c FROM Payment__c where id =: payment.id].Voided__c, false);

        }



        static testMethod void tesCreateSubscription_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Authorize.Net"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Subscription_Id__c FROM Subscription__c ].Subscription_Id__c, '7787847');
        }

        static testMethod void tesCreateSubscription_Card_Negative() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionErrorCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Authorize.Net"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 0);
        }

        static testMethod void tesCreateSubscription_Card_Negative_Exception() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionErrorCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":""},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 0);
        }

        static testMethod void tesUpdateSubscription_Card_Positive() {
            init(true);
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;
            Test.setMock(HttpCalloutMock.class, new AuthorizeUpdateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.updateSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Authorize.Net","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Subscription_Id__c FROM Subscription__c ].Subscription_Id__c, '7787847');
        }

        static testMethod void tesUpdateSubscription_Card_Negative() {
            init(true);
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;
            Test.setMock(HttpCalloutMock.class, new AuthorizeUpdateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.updateSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
        }

        static testMethod void tesCancelSubscription_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCancelSubscriptionCalloutMock());
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;

            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.cancelSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Authorize.Net","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Status__c FROM Subscription__c ].Status__c, 'InActive');
        }

        static testMethod void tesCancelSubscription_Card_Negative() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCancelSubscriptionCalloutMock());
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;

            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.cancelSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
        }

        static testMethod void tesGetSubscriptions_Card_Positive() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Authorize.Net"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Subscription_Id__c FROM Subscription__c ].Subscription_Id__c, '7787847');


            ManagePaymentDTOService.SubscriptionWrapper response2 = ManagePaymentService.getSubscriptions('{"carddetails":{},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Authorize.Net","product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            system.assert(response2.subscriptionDetails.size() >0);
        }

        static testMethod void tesRetrieveRecord_Positive() {
            init(true);
            Test.startTest();

            ManagePaymentDTOService.PaymentData response = ManagePaymentService.retrieveRecord([select id from Opportunity][0].id, 'Opportunity', 'Authorize.Net');
            Test.stopTest();
            system.assert(response != null);
        }
        
        static testMethod void tesProcessWebhook_Positive() {

            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf('{"notificationId":"93563fe2-5167-4748-ab8a-1711eab2d2af","eventType":"net.authorize.payment.authcapture.created","eventDate":"2021-11-05T09:32:01.4676216Z","webhookId":"f2cc88f7-a21f-4195-bb58-95c664a525ec","payload":{"responseCode":1,"authCode":"O1BSY4","avsResponse":"Y","authAmount":223.00,"entityName":"transaction","id":"60178879262"}}');
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/AuthorizeNetPaymentWebhook';
            req.httpMethod = 'POST';
        
            RestContext.request = req;
            RestContext.response= res;
        
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeGetTransactionCalloutMock());
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787427';
            insert sub;
            Test.startTest();
            AuthorizeNetPaymentWebhook.postPayment();
            //ManagePaymentService.processWebhook('{"notificationId":"93563fe2-5167-4748-ab8a-1711eab2d2af","eventType":"net.authorize.payment.authcapture.created","eventDate":"2021-11-05T09:32:01.4676216Z","webhookId":"f2cc88f7-a21f-4195-bb58-95c664a525ec","payload":{"responseCode":1,"authCode":"O1BSY4","avsResponse":"Y","authAmount":223.00,"entityName":"transaction","id":"60178879262"}}');
            Test.stopTest();
            system.assertEquals([ SELECT count() FROM Payment__c ], 1);

        }

        public class AuthorizeChargeTransactionCardCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"1","authCode":"SSQ5Y7","avsResultCode":"Y","cvvResultCode":"P","cavvResultCode":"2","transId":"40071777651","refTransID":"","transHash":"","testRequest":"0","accountNumber":"XXXX0027","accountType":"Visa","messages":[{"code":"1","description":"This transaction has been approved."}],"transHashSha2":"319A18B892D5A96C230E4FA2AA3486F60638C2410952863C6226330CF6F58247BE76F36CD89C93A7E12EC430A51D7FC97208B883BE65CA3E617B3326E5817B20","SupplementalDataQualificationIndicator":0,"networkTransId":"38KSJB7I9DO3CYX7Q08MWTW"},"refId":"0065e000002WY5Q","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }

        public class AuthorizeChargeTransactionBankCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"1","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"40071778449","refTransID":"","transHash":"","testRequest":"0","accountNumber":"XXXX0277","accountType":"eCheck","messages":[{"code":"1","description":"This transaction has been approved."}],"transHashSha2":"B5DC70771B6200BE7F445F468C6542CFED0C70A7C0814FBA23ED29C9033F19CE37148F82AE7C1980185163BB10DF2667ED269D7DD6D205DF7FD35ADFDEA9D655","SupplementalDataQualificationIndicator":0},"refId":"0065e000002WY5Q","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }
        public class AuthorizeChargeTransactionBankCalloutMockNegative implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"3","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"0","refTransID":"","transHash":"","testRequest":"0","accountNumber":"XXXX0277","accountType":"eCheck","errors":[{"errorCode":"9","errorText":"The ABA code is invalid"}],"transHashSha2":"E1ABC5B0FCBB5479C371CD69B44EE90FD21044A6FC8474DD0F58139F6A0AE26B7C5777C80976FB7C79D517773196CFE4856C7A19D33EACD3763CDC8E2D3F5F72","SupplementalDataQualificationIndicator":0},"refId":"0065e000002WY5Q","messages":{"resultCode":"Error","message":[{"code":"E00027","text":"The transaction was unsuccessful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }


        public class AuthorizeNetHttpPostPaymentCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transaction1":{"transId":"40068188237","submitTimeUTC":"2021-06-25T18:12:10.193Z","submitTimeLocal":"2021-06-25T11:12:10.193","transactionType":"authCaptureTransaction","transactionStatus":"capturedPendingSettlement","responseCode":1,"responseReasonCode":1,"responseReasonDescription":"Approval","authCode":"RI68FK","AVSResponse":"Y","cardCodeResponse":"P","FDSFilterAction":"report","FDSFilters":[{"name":"Amount Filter","action":"report"}],"authAmount":2222.00,"settleAmount":2222.00,"taxExempt":false,"payment":{"creditCard":{"cardNumber":"XXXX0027","expirationDate":"XXXX","cardType":"Visa"}},"customer":{"email":"test@test.com"},"billTo":{"firstName":"FName","lastName":"LName","address":"add1","city":"city","state":"ny","zip":"08990","country":"US"},"shipTo":{"firstName":"FName","lastName":"LName","address":"add1","city":"city","state":"ny","zip":"08990","country":"US"},"recurringBilling":false,"customerIP":"24.45.193.119","product":"Card Not Present","marketType":"eCommerce","networkTransId":"NBIN799Z3QILG7D4HVRLEM5","authorizationIndicator":"final"},"clientId":"accept-hosted","transrefId":"0065e000002WY5Q","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class AuthorizeNetHttpRefundCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"1","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"40069326178","refTransID":"40068188237","transHash":"","testRequest":"0","accountNumber":"XXXX0027","accountType":"Visa","messages":[{"code":"1","description":"This transaction has been approved."}],"transHashSha2":"19C59F8D06931BFBD4B43D285E3CACF90044F0A65DE1CA194B29ADC6B5C0932B1463197D18CB5DC43C696F6FFA70E70BC6C8BAE9EC0CBD0410478CBAFFF3969E","SupplementalDataQualificationIndicator":0},"refId":"","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class AuthorizeNetHttpRefundErrorCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"3","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"0","refTransID":"40071555181","transHash":"","testRequest":"0","accountNumber":"XXXX0027","accountType":"Visa","errors":[{"errorCode":"11","errorText":"A duplicate transaction has been submitted."}],"transHashSha2":"E1ABC5B0FCBB5479C371CD69B44EE90FD21044A6FC8474DD0F58139F6A0AE26B7C5777C80976FB7C79D517773196CFE4856C7A19D33EACD3763CDC8E2D3F5F72","SupplementalDataQualificationIndicator":0},"messages":{"resultCode":"Error","message":[{"code":"E00027","text":"The transaction was unsuccessful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class AuthorizeNetHttpVoidCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"1","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"40071782661","refTransID":"40071782661","transHash":"","testRequest":"0","accountNumber":"XXXX0027","accountType":"Visa","messages":[{"code":"1","description":"This transaction has been approved."}],"transHashSha2":"0962A09E109A32A5A017B95E368289F0D8B7722B4E2A1A1BBD339386C09B2951E9654A957C9A8079C074AA1C44E494B256ED3A75446BE8D15E18B88012F6973C","SupplementalDataQualificationIndicator":0},"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class AuthorizeNetHttpVoidErrorCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transactionResponse":{"responseCode":"1","authCode":"","avsResultCode":"P","cvvResultCode":"","cavvResultCode":"","transId":"0","refTransID":"40071782661","transHash":"","testRequest":"0","accountNumber":"","accountType":"Visa","messages":[{"code":"310","description":"This transaction has already been voided."}],"transHashSha2":"266FE2E7AA0013EE7E38E75A8E39BB6EB942C2A7F8208A0ECE593CB67B8750D1789AC8C1324BBE4DB8433115CE65C80D915491CACF958DB84186CA404EEB75D7","SupplementalDataQualificationIndicator":0},"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }

        public class AuthorizeCreateSubscriptionCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"subscriptionId":"7787847","profile":{"customerProfileId":"902335517","customerPaymentProfileId":"902159224"},"refId":"00Q5e0000050XnjEAE","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }

        public class AuthorizeCreateSubscriptionErrorCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"refId":"00Q5e0000050XnjEAE","messages":{"resultCode":"Error","message":[{"code":"E00012","text":"You have submitted a duplicate of Subscription 7788411. A duplicate subscription will not be created."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }


        public class AuthorizeUpdateSubscriptionCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"profile":{"customerProfileId":"902335195","customerPaymentProfileId":"902158904"},"refId":"00Q5e0000050XnjEAE","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }
        public class AuthorizeCancelSubscriptionCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"refId":"00Q5e0000050XnjEAE","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }

        public class AuthorizegetSubscriptionsCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"totalNumInResultSet":1,"subscriptionDetails":[{"id":7788411,"name":"test","status":"active","createTimeStampUTC":"2021-11-05T13:56:50.55","firstName":"Norm","lastName":"May","totalOccurrences":1,"pastOccurrences":0,"paymentMethod":"creditCard","accountNumber":"XXXX0027","invoice":"","amount":223.00,"currencyCode":"USD","customerProfileId":902338860,"customerPaymentProfileId":902162688}],"refId":"00Q5e0000050XnjEAE","messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }


        public class AuthorizeGetTransactionCalloutMock implements HttpCalloutMock {
            // Implement this interface method
             public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"transaction1":{"transId":"60178879262","submitTimeUTC":"2021-11-05T09:32:01.38Z","submitTimeLocal":"2021-11-05T02:32:01.38","transactionType":"authCaptureTransaction","transactionStatus":"capturedPendingSettlement","responseCode":1,"responseReasonCode":1,"subscription":{"id":7787427,"payNum":1},"responseReasonDescription":"Approval","authCode":"O1BSY4","AVSResponse":"Y","cardCodeResponse":"P","authAmount":223.00,"settleAmount":223.00,"taxExempt":false,"payment":{"creditCard":{"cardNumber":"XXXX0027","expirationDate":"XXXX","cardType":"Visa"}},"billTo":{"firstName":"Norm","lastName":"May"},"recurringBilling":false,"product":"Card Not Present","marketType":"eCommerce","networkTransId":"QMJLQWUM0ONVWPFMPJUSDNF","authorizationIndicator":"final"},"messages":{"resultCode":"Ok","message":[{"code":"I00001","text":"Successful."}]}}');
                response.setStatusCode(200);
                return response; 
            }
        }

        
}