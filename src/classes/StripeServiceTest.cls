@isTest
private class StripeServiceTest {
            
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
                pconfig.Name = 'Stripe';
                pconfig.Object_Api_Name__c = 'Opportunity';
                pconfig.Auth_API_Login_Id__c = 'Auth_API_Login_Id__c';
                pconfig.Auth_Transaction_Key__c = 'Auth_Transaction_Key__c';
                pconfig.Amount_API_Name__c = 'Amount';
                
                insert pconfig;

                pconfig = new Payment_Configuration__c();
                if(log)
                pconfig.Enable_Logging__c = true;
                pconfig.Name = 'Stripe';
                pconfig.Object_Api_Name__c = 'Opportunity';
                pconfig.Secret_Key__c = 'Secret_Key__c';
                pconfig.Amount_API_Name__c = 'Amount';
                
                insert pconfig;

        }
    
        static testMethod void Stripe_testChargeTransaction_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new StripeChargeTransactionCardCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Stripe","product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertEquals([ SELECT Amount__c FROM Payment__c ].Amount__c, 223);
        }

        /*static testMethod void Stripe_testChargeTransaction_Bank_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new StripeChargeTransactionBankCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"LName","cardHolderFirstName":"FName","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"test@test.com"},"addressdetails":{"BillingCountry":"United States","BillingStreet":"add1","BillingCity":"city","BillingPostalCode":"08990","BillingState":"NY"},"otherdetails":{"product":"testproduct","amount":"22","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity", "paymentserviceprovider":"Stripe"},"bankdetails":{"accountType":"checking","routingNumber":"063100277","accountNumber":"063100277","nameOnAccount":"Test"}}');
            Test.stopTest();
            system.debug('LOG==>' + [ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ]);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertEquals([ SELECT Amount__c FROM Payment__c ].Amount__c, 22);
        }*/
    
        static testMethod void Stripe_testChargeTransaction_Card_Negative() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new StripeChargeTransactionCardCalloutMockNegative());
            Test.startTest();
            ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"LName","cardHolderFirstName":"FName","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"test@test.com"},"addressdetails":{"BillingCountry":"United States","BillingStreet":"add1","BillingCity":"city","BillingPostalCode":"08990","BillingState":"NY"},"otherdetails":{"product":"testproduct","amount":"22","refid":"0065e000002WY5Q","fieldapiname":"Opportunity__c","objectapiname":"Opportunity", "paymentserviceprovider":"Stripe"},"bankdetails":{"accountType":"checking","routingNumber":"063100277","accountNumber":"063100277","nameOnAccount":"Test"}}');
            Test.stopTest();
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 0);
        }

        static testMethod void Stripe_refundTransaction_Positive() {
            init(true);

            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Stripe';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new StripeHttpRefundCalloutMock());

            ManagePaymentService.refundTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 2);
            //system.assertEquals([ SELECT Refund_Result_Code__c FROM Payment__c where id =: payment.id].Refund_Result_Code__c, 'Ok');
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id =: payment.id].Refunded__c, true);
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id !=: payment.id].Refunded__c, true);
            system.assertEquals([ SELECT Amount__c FROM Payment__c where id !=: payment.id].Amount__c, -30);

        }   

        static testMethod void Stripe_refundTransaction_Negative() {
            init(true);
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Stripe';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;

            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new StripeHttpRefundErrorCalloutMock());

            ManagePaymentService.refundTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            system.assertNotEquals([ SELECT Refund_Result_Code__c FROM Payment__c where id =: payment.id].Refund_Result_Code__c, 'Ok');
            system.assertEquals([ SELECT Refunded__c FROM Payment__c where id =: payment.id].Refunded__c, false);

        }

        static testMethod void Stripe_voidTransaction_Positive() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new StripeChargeTransactionCardCalloutMock());
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Stripe","product":"GC5000 series","amount":223,"refid":"0065e000002WY5QAAW","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Stripe';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';

            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new StripeHttpVoidCalloutMock());

            ManagePaymentService.voidTransaction(payment.id);
            Test.stopTest();
    
            system.assertEquals([ SELECT Id FROM Payment__c ].size(), 2);
            system.assertEquals([ SELECT Voided__c FROM Payment__c where id =: payment.id].Voided__c, true);
            system.assertEquals([ SELECT Voided__c FROM Payment__c where id !=: payment.id].Voided__c, true);
            system.assertEquals([ SELECT Amount__c FROM Payment__c where id !=: payment.id].Amount__c, -30);

        }

        static testMethod void Stripe_voidTransaction_Negative() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new StripeChargeTransactionCardCalloutMock());
            ManagePaymentDTOService.ChargeTransactionResponse response = ManagePaymentService.chargeTransaction('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 22","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{"BillingStreet":"23 Ave D","BillingCity":"Norwalk","BillingState":"CT","BillingPostalCode":"06902","BillingCountry":"USA","internationalAddress":false},"otherdetails":{"paymentserviceprovider":"Stripe","product":"GC5000 series","amount":223,"refid":"0065e000002WY5QAAW","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            System.debug('response====>' + response);
            Payment__c payment = new Payment__c();
            payment.Transaction_Id__c = 'Transaction_Id__c';
            payment.SObect_API_Name__c = 'Opportunity';
            payment.Source__c = 'Stripe';
            payment.Amount__c = 30;
            payment.Card_Number__c = '2222222222';
            
            
            insert payment;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new StripeHttpVoidErrorCalloutMock());

            ManagePaymentService.voidTransaction(payment.id);
            Test.stopTest();
    
            //system.assertEquals([ SELECT Id FROM Payment__c ].size(), 1);
            //system.assertEquals([ SELECT Voided__c FROM Payment__c where id =: payment.id].Voided__c, false);

        }

        static testMethod void Stripe_updateSubscription_Positive() {
            StripeServiceHelper.updateSubscription(null);

        }
        static testMethod void Stripe_createSubscription_Positive() {
            StripeServiceHelper.createSubscription(null);

        }
        static testMethod void Stripe_cancelSubscription_Positive() {
            StripeServiceHelper.cancelSubscription(null);

        }

        static testMethod void Stripe_createCustomer_Positive() {
            StripeServiceHelper.createCustomer(null);

        }

/*
        static testMethod void Stripe_tesCreateSubscription_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Stripe"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
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
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Stripe"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 0);
        }

        static testMethod void Stripe_tesCreateSubscription_Card_Negative_Exception() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionErrorCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":""},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(false, response.success);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 0);
        }

        static testMethod void Stripe_tesUpdateSubscription_Card_Positive() {
            init(true);
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;
            Test.setMock(HttpCalloutMock.class, new AuthorizeUpdateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.updateSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Stripe","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Subscription_Id__c FROM Subscription__c ].Subscription_Id__c, '7787847');
        }

        static testMethod void Stripe_tesUpdateSubscription_Card_Negative() {
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

        static testMethod void Stripe_tesCancelSubscription_Card_Positive() {
            init(true);
            Test.setMock(HttpCalloutMock.class, new AuthorizeCancelSubscriptionCalloutMock());
            Subscription__c sub = new Subscription__c();
            sub.Subscription_Id__c = '7787847';
            insert sub;

            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.cancelSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"222","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Stripe","refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","subscriptionId":7787847},"bankdetails":{},"subdetails":{}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Status__c FROM Subscription__c ].Status__c, 'InActive');
        }

        static testMethod void Stripe_tesCancelSubscription_Card_Negative() {
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

        static testMethod void Stripe_tesGetSubscriptions_Card_Positive() {
            init(true);

            Test.setMock(HttpCalloutMock.class, new AuthorizeCreateSubscriptionCalloutMock());
            Test.startTest();
            ManagePaymentDTOService.SubscriptionTransactionResponse response = ManagePaymentService.createSubscription('{"carddetails":{"cardNumber":"4007 0000 0002 7","cardHolderLastName":"May","cardHolderFirstName":"Norm","cardCVV":"333","cardExpiry":"02 / 23","cardType":"visa","cardEmail":"norm_may@greenwich.net"},"addressdetails":{},"otherdetails":{"product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity","paymentserviceprovider":"Stripe"},"bankdetails":{},"subdetails":{"subname":"Hello","startdate":"2021-11-05","occurrances":"12","amount":"223","unit":"Monthly"}}');
            Test.stopTest();
            system.debug('LOGGG===>'+[ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c);
            system.assertEquals(true, response.success);
            system.assertEquals([ SELECT Error_Message__c, Request_Body__c, Response_Body__c, Status_Code__c FROM API_Tracker__c ].Error_Message__c, null);
            system.assertEquals([ SELECT count() FROM Subscription__c ], 1);
            system.assertEquals([ SELECT Subscription_Id__c FROM Subscription__c ].Subscription_Id__c, '7787847');


            ManagePaymentDTOService.SubscriptionWrapper response2 = ManagePaymentService.getSubscriptions('{"carddetails":{},"addressdetails":{},"otherdetails":{"paymentserviceprovider":"Stripe","product":"GC5000 series","amount":223,"refid":"'+opportunityObj.id+'","fieldapiname":"Opportunity__c","objectapiname":"Opportunity"},"bankdetails":{},"subdetails":{}}');
            system.assert(response2.subscriptionDetails.size() >0);
        }

        static testMethod void Stripe_tesRetrieveRecord_Positive() {
            init(true);
            Test.startTest();

            ManagePaymentDTOService.PaymentData response = ManagePaymentService.retrieveRecord([select id from Opportunity][0].id, 'Opportunity', 'Stripe');
            Test.stopTest();
            system.assert(response != null);
        }
        
        static testMethod void Stripe_tesProcessWebhook_Positive() {

        

        }*/

        public class StripeChargeTransactionCardCalloutMock implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"id":"ch_3K0CzBI393PNWqcg1Wf58Ai9","object":"charge","amount":22330,"amount_captured":22330,"amount_refunded":0,"application":null,"application_fee":null,"application_fee_amount":null,"balance_transaction":"txn_3K0CzBI393PNWqcg1qni901g","billing_details":{"address":{"city":"Norwalk","country":"USA","line1":"1301 Hoch Drive","line2":null,"postal_code":"06902","state":"CT"},"email":null,"name":"Andy Young","phone":null},"calculated_statement_descriptor":"STRIPE* GC5000 SERIES","captured":true,"created":1637966021,"currency":"usd","customer":null,"description":"GC5000 series","destination":null,"dispute":null,"disputed":false,"failure_code":null,"failure_message":null,"fraud_details":{},"invoice":null,"livemode":false,"metadata":{"order_id":"00Q5e0000050XnjEAE"},"on_behalf_of":null,"order":null,"outcome":{"network_status":"approved_by_network","reason":null,"risk_level":"normal","risk_score":36,"seller_message":"Payment complete.","type":"authorized"},"paid":true,"payment_intent":null,"payment_method":"card_1K0CzBI393PNWqcg1aaMYAzE","payment_method_details":{"card":{"brand":"visa","checks":{"address_line1_check":"pass","address_postal_code_check":"pass","cvc_check":"pass"},"country":"US","exp_month":2,"exp_year":2023,"fingerprint":"HWXUpDItvNBNP25P","funding":"credit","installments":null,"last4":"4242","network":"visa","three_d_secure":null,"wallet":null},"type":"card"},"receipt_email":"norm_may@greenwich.net","receipt_number":null,"receipt_url":"https://pay.stripe.com/receipts/acct_1JsIa9I393PNWqcg/ch_3K0CzBI393PNWqcg1Wf58Ai9/rcpt_KfY5ydQBS1AxvPl2pwmBDum1ZJozYTU","refunded":false,"refunds":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/charges/ch_3K0CzBI393PNWqcg1Wf58Ai9/refunds"},"review":null,"shipping":null,"source":{"id":"card_1K0CzBI393PNWqcg1aaMYAzE","object":"card","address_city":"Norwalk","address_country":"USA","address_line1":"1301 Hoch Drive","address_line1_check":"pass","address_line2":null,"address_state":"CT","address_zip":"06902","address_zip_check":"pass","brand":"Visa","country":"US","customer":null,"cvc_check":"pass","dynamic_last4":null,"exp_month":2,"exp_year":2023,"fingerprint":"HWXUpDItvNBNP25P","funding":"credit","last4":"4242","metadata":{},"name":"Andy Young","tokenization_method":null},"source_transfer":null,"statement_descriptor":"GC5000 series","statement_descriptor_suffix":"GC5000 series","status":"succeeded","transfer_data":null,"transfer_group":null}');
                response.setStatusCode(200);
                return response; 
            }
        }

        public class StripeChargeTransactionCardCalloutMockNegative implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"error":{"charge":"ch_3K0D5iI393PNWqcg1rqT9Qwb","code":"card_declined","decline_code":"test_mode_live_card","doc_url":"https://stripe.com/docs/error-codes/card-declined","message":"Your card was declined. Your request was in test mode, but used a non test (live) card. For a list of valid test cards, visit: https://stripe.com/docs/testing.","type":"card_error"}}');
                response.setStatusCode(200);
                return response; 
            }
        }


        public class StripeHttpRefundCalloutMock implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"id":"re_3K0D43I393PNWqcg1wor80hj","object":"refund","amount":22330,"balance_transaction":"txn_3K0D43I393PNWqcg1cW2z6ud","charge":"ch_3K0D43I393PNWqcg19rfbrdp","created":1637966534,"currency":"usd","metadata":{"order_id":"a015e00000RCsTRAA1"},"payment_intent":null,"reason":"requested_by_customer","receipt_number":null,"source_transfer_reversal":null,"status":"succeeded","transfer_reversal":null}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class StripeHttpRefundErrorCalloutMock implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"error":{"code":"charge_already_refunded","doc_url":"https://stripe.com/docs/error-codes/charge-already-refunded","message":"Charge ch_3K0D43I393PNWqcg19rfbrdp has already been refunded.","type":"invalid_request_error"}}');
                response.setStatusCode(500);
                return response; 
            }
        }
    
        public class StripeHttpVoidCalloutMock implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"id":"re_3K0D43I393PNWqcg1wor80hj","object":"refund","amount":22330,"balance_transaction":"txn_3K0D43I393PNWqcg1cW2z6ud","charge":"ch_3K0D43I393PNWqcg19rfbrdp","created":1637966534,"currency":"usd","metadata":{"order_id":"a015e00000RCsTRAA1"},"payment_intent":null,"reason":"requested_by_customer","receipt_number":null,"source_transfer_reversal":null,"status":"succeeded","transfer_reversal":null}');
                response.setStatusCode(200);
                return response; 
            }
        }
    
        public class StripeHttpVoidErrorCalloutMock implements HttpCalloutMock {
            // Implement this interface method
                public HTTPResponse respond(HTTPRequest request) {
                // Create a fake response
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"error":{"code":"charge_already_refunded","doc_url":"https://stripe.com/docs/error-codes/charge-already-refunded","message":"Charge ch_3K0D43I393PNWqcg19rfbrdp has already been refunded.","type":"invalid_request_error"}}');
                response.setStatusCode(340);
                return response; 
            }
        }

        
}