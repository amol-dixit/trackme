/**
 * This class is responsible to serve all the transactions realated to Stripe. 
 * It implements the PaymentServiceInterface
 * 
 */public with sharing class StripeServiceHelper {
	public static ManagePaymentDTOService.Transaction_Reponse_Wrapper createCustomer(ManagePaymentDTOService.PaymentDetails paymentDetails){
		return null;
	}

	public static ManagePaymentDTOService.Transaction_Reponse_Wrapper processChargeTransaction(ManagePaymentDTOService.PaymentDetails paymentDetails, String company, Decimal amount, String secretkey){

			Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(paymentDetails.otherdetails.objectapiname, paymentDetails.otherdetails.paymentserviceprovider);

			System.debug('paymentDetails===>' + paymentDetails.serviceChargeTransaction);

			
            Map<String, Object> parameters = createChargeTransactionData(paymentDetails, amount);
            String requestbody = Util.generateURLParameters(parameters);
            System.debug('requestbody==>' + requestbody);
    
    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(pconfig.Endpoint_Url__c + '/v1/charges');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer '+ secretkey);
            request.setBody(requestbody);
    
            
            request.setHeader('content-type','application/x-www-form-urlencoded');
            Http http = new Http();
    
            HttpResponse res = http.send(request);
            System.debug('GET BODY--->' + res.getBody());
            ManagePaymentDTOService.Transaction_Reponse_Wrapper tr = new ManagePaymentDTOService.Transaction_Reponse_Wrapper();
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            tr.requestString = requestbody;
            tr.amount = amount.setScale(2);
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

			return tr;

	}

	public class PaymentDataWrapper{

        public Payment__c paymentObj;
        public String company;
        public Decimal amount; 
        public String apilogin;
        public String authKey;
        public String transactionId;
        public PaymentDataWrapper(Payment__c paymentObj, String company, Decimal amount, String apilogin, String authKey, String transactionId){
            this.paymentObj = paymentObj;
            this.company = company;
            this.amount = amount;
            this.apilogin = apilogin;
            this.authKey = authKey;
            this.transactionId = transactionId;
        }
    }

	public static ManagePaymentDTOService.Transaction_Reponse_Wrapper processRefundTransaction(PaymentDataWrapper pdw){
        Payment_Configuration__c pconfig = ManagePaymentServiceHelper.getPaymentConfig(pdw.paymentObj.SObect_API_Name__c, pdw.paymentObj.Source__c);

		List<ManagePaymentDTOService.Transaction_Reponse_Wrapper> wrapperList = new List<ManagePaymentDTOService.Transaction_Reponse_Wrapper>();

		Map<String, Object> parameters = createRefundData(pdw);
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
			tr.refId = pdw.paymentObj.Customer_Id__c;
			tr.transId = (String)response.get('id');
			tr.responseMessage = (String)response.get('status');
		}else{
			tr.responseMessage = 'Code :: ' + (String)((Map<String, Object>)response.get('error')).get('code') + ' :: Message :: '+ (String)((Map<String, Object>)response.get('error')).get('message') + + ' :: Type :: '+ (String)((Map<String, Object>)response.get('error')).get('type');
		}
		return tr;

    }


	public static Map<String, Object> createChargeTransactionData(ManagePaymentDTOService.PaymentDetails paymentDetails, Decimal amount){
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
		parameters.put('amount', String.valueOf(amount.setScale(2)).replace('.',''));
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
		System.debug('parameters==>' + parameters);
		return parameters;
	}

	        /**
         * This method is reponsible to void the transaction for Stripe. It accepts the PaymentDetails wrapper with all the details.
         * @param  ManagePaymentDTOService.PaymentDetails : This wrapper contains all the required data to do the transaction.
         * @return ManagePaymentDTOService.Transaction_Reponse_Wrapper : It returns the wrapper with the Success/Failure response.
         */
        public static Map<String, Object> createRefundData(PaymentDataWrapper pdw){
            Map<String, Object> parameters = new Map<String, Object>();
    
            //parameters.put('object', 'refund');
            parameters.put('charge', pdw.transactionId);
            parameters.put('reason', 'requested_by_customer');
            
            // Add transaction metadata
            Map<String, Object> metadata = new Map<String, Object>();
            metadata.put('order_id', pdw.paymentObj.id);
            //if (options.ip != null) metadata.put('ip', options.ip);
            //if (options.invoice != null) metadata.put('invoice', options.invoice);
            parameters.put('metadata', metadata);
            return parameters;
        }


}