/**
 * This class is responsible to serve all the transactions realated to Stripe. 
 * It implements the PaymentServiceInterface
 * 
 */public with sharing class StripeService implements PaymentServiceInterface{    
        /**
         * This method is reponsible to charge the transaction for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
        public static ManagePaymentDTOService.Transaction_Reponse_Wrapper chargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails){
            Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
    
            Map<String, Object> parameters = createChargeTransactionData(paymentDetails);
            String requestbody = Util.generateURLParameters(parameters);
            System.debug('requestbody==>' + requestbody);
    
    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(pconfig.Endpoint_Url__c + '/v1/charges');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+ pconfig.Secret_Key__c);
            request.setBody(requestbody);
    
            
            request.setHeader('content-type','application/x-www-form-urlencoded');
            Http http = new Http();
    
            HttpResponse res = http.send(request);
            System.debug('GET BODY--->' + res.getBody());
            ManagePaymentDTOService.Transaction_Reponse_Wrapper tr = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            tr.requestString = requestbody;
            tr.amount = paymentDetails.otherdetails.amount.setScale(2);
            tr.responseString = res.getBody();
            tr.statusCode = res.getStatusCode();
            tr.issuccess = res.getStatusCode() == 200 ? true : false;
            if(tr.issuccess){
                tr.refId = paymentDetails.otherdetails.refId;
                tr.transId = (String)response.get('id');
                tr.authCode = null;
                //tr.authCode = 
                tr.accountNumber = 'XXXX'+ (String)((Map<String, Object>)((Map<String, Object>)response.get('payment_method_details')).get('card')).get('last4');
                tr.accountType = (String)((Map<String, Object>)((Map<String, Object>)response.get('payment_method_details')).get('card')).get('brand');
                tr.responseMessage = (String)((Map<String, Object>)response.get('outcome')).get('seller_message');
            }else{
                tr.responseMessage = 'Code :: ' + (String)((Map<String, Object>)response.get('error')).get('code') + ' :: Message :: '+ (String)((Map<String, Object>)response.get('error')).get('message') + + ' :: Type :: '+ (String)((Map<String, Object>)response.get('error')).get('type');
            }
            //tr.resultCode = 
            return tr;
    
    
        }
    
        /**
         * This method is reponsible to update a Subscription for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.PaymentDetails : It returns the wrapper with the Success/Failure response.
         */
        public static ManagePaymentDTOService.Sub_Reponse_Wrapper updateSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
            return null;
        }
    
        /**
         * This method is reponsible to cancel a Subscription for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.SubscriptionWrapper : It returns the wrapper with the Success/Failure response.
         */
        public static ManagePaymentDTOService.Sub_Reponse_Wrapper cancelSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
            return null;
        }
        
        /**
         * This method is reponsible to create a Subscription for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Sub_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
        public static ManagePaymentDTOService.Sub_Reponse_Wrapper createSubscription(ManagePaymentDTOService.PaymentDetails paymentDetails){
            /*Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
    
            Map<String, Object> parameters = createSubscriptionData(paymentDetails);
            String requestbody = Util.generateURLParameters(parameters);
            System.debug('requestbody==>' + requestbody);
    
    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(pconfig.Endpoint_Url__c + '/v1/subscriptions');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+ pconfig.Secret_Key__c);
            request.setBody(requestbody);
            //System.debug('parameters===>' + Json.serialize(parameters));
    
            
            request.setHeader('content-type','application/x-www-form-urlencoded');
            Http http = new Http();
    
            HttpResponse res = http.send(request);
    
    
            System.debug('GET BODY--->' + res.getBody());
            ManagePaymentDTOService.Sub_Reponse_Wrapper tr = new ManagePaymentDTOService.Sub_Reponse_Wrapper();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            tr.requestString = requestbody;
            tr.responseString = res.getBody();
            tr.statusCode = res.getStatusCode();
            return tr;*/
            return null;
        }
    
            /**
         * This method is reponsible to void the transaction for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
    
        public static List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> voidTransaction(List<Payment__c> paymentList){
            return refundTransaction(paymentList);
        }
    
    
        /**
         * This method is reponsible to refund the transaction for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
        public static List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> refundTransaction(List<Payment__c> paymentList){
    
            Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentList[0].SObect_API_Name__c, paymentList[0].Source__c);
            List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> wrapperList = new List<ManagePaymentDTOService.Transaction_Reponse_Wrapper>();
            for(Payment__c paymentObj :  paymentList){
    
            Map<String, Object> parameters = createRefundData(paymentObj);
            String requestbody = Util.generateURLParameters(parameters);
            System.debug('requestbody==>' + requestbody);
    
    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(pconfig.Endpoint_Url__c + '/v1/refunds');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+ pconfig.Secret_Key__c);
            request.setBody(requestbody);
    
            
            request.setHeader('content-type','application/x-www-form-urlencoded');
            Http http = new Http();
    
            HttpResponse res = http.send(request);
            System.debug('GET BODY--->' + res.getBody());
            ManagePaymentDTOService.Transaction_Reponse_Wrapper tr = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            tr.requestString = requestbody;
            tr.responseString = res.getBody();
            tr.statusCode = res.getStatusCode();
            tr.issuccess = res.getStatusCode() == 200 ? true : false;
            if(tr.issuccess){
                tr.refId = paymentObj.Customer_Id__c;
                tr.transId = (String)response.get('id');
                tr.responseMessage = (String)response.get('status');
            }else{
                tr.responseMessage = 'Code :: ' + (String)((Map<String, Object>)response.get('error')).get('code') + ' :: Message :: '+ (String)((Map<String, Object>)response.get('error')).get('message') + + ' :: Type :: '+ (String)((Map<String, Object>)response.get('error')).get('type');
            }
            wrapperList.add(tr);
            }
            return wrapperList;
        }
    
        /**
         * This method is reponsible to void the transaction for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
        public static Map<String, Object> createRefundData(Payment__c paymentObj){
            Map<String, Object> parameters = new Map<String, Object>();
    
            //parameters.put('object', 'refund');
            parameters.put('charge', paymentObj.Transaction_Id__c);
            parameters.put('reason', 'requested_by_customer');
            
            // Add transaction metadata
            Map<String, Object> metadata = new Map<String, Object>();
            metadata.put('order_id', paymentObj.id);
            //if (options.ip != null) metadata.put('ip', options.ip);
            //if (options.invoice != null) metadata.put('invoice', options.invoice);
            parameters.put('metadata', metadata);
            return parameters;
        }
    
            /**
         * This method is reponsible to get a related Subscriptions for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.SubscriptionWrapper : It returns the wrapper with the Success/Failure response.
         */
        public static ManagePaymentDTOService.SubscriptionWrapper getSubscriptions(ManagePaymentDTOService.PaymentDetails paymentDetails){
            /*Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);
    
                // Make the API request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.stripe.com/v1/subscriptions?status=all&limit=100');
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + pconfig.Secret_Key__c);
            HttpResponse response = http.send(request);
            
            System.debug(response.getStatusCode());
            if (response.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    
                // Do something with the data
                List<Object> items = (List<Object>) results.get('data');
                System.debug('Received the following items:');
                for (Object item: items) {
                    System.debug(item);
                }
    
                // See if there is more data
                Object hasMore = results.get('has_more');
                if (hasMore == true) {
                    system.debug('more data');
                } else {
                    system.debug('no more data');
                }
    
            }
            return null;
            */
            return null;
        }
    
        public static Map<String, Object> createChargeTransactionData(ManagePaymentDTOService.PaymentDetails paymentDetails){
            Map<String, Object> parameters = new Map<String, Object>();
            Map<String, Object> cardSource = new Map<String, Object> {
                'object' => 'card',
                'number' => paymentDetails.carddetails.cardNumber,
                'exp_month' => paymentDetails.carddetails.cardExpiry.split('/')[0].trim(),
                'exp_year' => '20'+paymentDetails.carddetails.cardExpiry.split('/')[1].trim(),
                'cvc' => paymentDetails.carddetails.cardCVV,
                'name' => paymentDetails.carddetails.cardHolderFirstName + ' '+ paymentDetails.carddetails.cardHolderLastName,
                'address_line1' => paymentDetails.addressdetails.BillingStreet,
                'address_line2' => paymentDetails.addressdetails.BillingStreet2,
                'address_city' => paymentDetails.addressdetails.BillingCity,
                'address_state' => paymentDetails.addressdetails.BillingState,
                'address_zip' => paymentDetails.addressdetails.BillingPostalCode,
                'address_country' => paymentDetails.addressdetails.BillingCountry
            };
            parameters.put('source', cardSource);
            System.debug('paymentDetails===>' + paymentDetails);
            parameters.put('amount', String.valueOf(paymentDetails.otherdetails.amount.setScale(2)).replace('.',''));
            parameters.put('capture', 'true');	
    
            parameters.put('currency', 'usd');
            parameters.put('description', paymentDetails.otherdetails.product);
            parameters.put('statement_descriptor', paymentDetails.otherdetails.product);
            parameters.put('receipt_email', paymentDetails.carddetails.cardEmail);
    
            // Add transaction metadata
            Map<String, Object> metadata = new Map<String, Object>();
            metadata.put('order_id', paymentDetails.otherdetails.refId);
            //if (options.ip != null) metadata.put('ip', options.ip);
            //if (options.invoice != null) metadata.put('invoice', options.invoice);
            parameters.put('metadata', metadata);
            return parameters;
        }
    
        public static Map<String, Object> createSubscriptionData(ManagePaymentDTOService.PaymentDetails paymentDetails){
            /*Map<String, Object> parameters = new Map<String, Object>();
            parameters.put('customer', paymentDetails.otherdetails.refId);
    
            Map<String, Object> cardSource = new Map<String, Object> {
                'object' => 'card',
                'number' => paymentDetails.carddetails.cardNumber,
                'exp_month' => paymentDetails.carddetails.cardExpiry.split('/')[0].trim(),
                'exp_year' => '20'+paymentDetails.carddetails.cardExpiry.split('/')[1].trim(),
                'cvc' => paymentDetails.carddetails.cardCVV,
                'name' => paymentDetails.carddetails.cardHolderFirstName + ' '+ paymentDetails.carddetails.cardHolderLastName,
                'address_line1' => paymentDetails.addressdetails.BillingStreet,
                'address_line2' => paymentDetails.addressdetails.BillingStreet2,
                'address_city' => paymentDetails.addressdetails.BillingCity,
                'address_state' => paymentDetails.addressdetails.BillingState,
                'address_zip' => paymentDetails.addressdetails.BillingPostalCode,
                'address_country' => paymentDetails.addressdetails.BillingCountry
            };
            parameters.put('source', cardSource);
            parameters.put('collection_method', 'charge_automatically');
            
    
            Map<String, Object> subitem = new Map<String, Object> {
                'object' => 'subscription_item',
                'quantity' => 1,
                'price' => new Map<String, Object> {
    
                    'recurring' => new Map<String, Object> {
                        'interval' => 'month',
                        'interval_count' => 1
                    }
                }
            };
    
            parameters.put('items', new List<Map<String, Object>>{
                new Map<String, Object>{
                    'object' => 'list',
                    'data' => new List<Map<String, Object>>{subitem}
                }
            });
            //parameters.put('amount', '32122');
            //parameters.put('capture', 'true');
    
            //parameters.put('currency', 'usd');
            //parameters.put('description', paymentDetails.otherdetails.product);
            //parameters.put('statement_descriptor', paymentDetails.otherdetails.product);
            //parameters.put('receipt_email', paymentDetails.carddetails.cardEmail);
    
            // Add transaction metadata
            Map<String, Object> metadata = new Map<String, Object>();
            metadata.put('order_id', paymentDetails.otherdetails.refId);
            //if (options.ip != null) metadata.put('ip', options.ip);
            //if (options.invoice != null) metadata.put('invoice', options.invoice);
            parameters.put('metadata', metadata);
    
    
            System.debug('parameters===>' + Json.serialize(parameters));
            return parameters;*/
    
            return null;
        }
    
    }