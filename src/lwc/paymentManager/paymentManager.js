import { LightningElement, track, wire, api} from 'lwc';
import chargeTransaction from '@salesforce/apex/ManagePaymentService.chargeTransaction';
import createSubscription from '@salesforce/apex/ManagePaymentService.createSubscription';
import retrieveRecord from '@salesforce/apex/ManagePaymentService.retrieveRecord';
import getSubscriptions from '@salesforce/apex/ManagePaymentService.getSubscriptions';
import cancelSubscription from '@salesforce/apex/ManagePaymentService.cancelSubscription';
import updateSubscription from '@salesforce/apex/ManagePaymentService.updateSubscription';
import decryptURL from '@salesforce/apex/ManagePaymentService.decryptURL';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";


export default class PaymentManager extends  NavigationMixin(LightningElement)  {
  @api isLoaded = false;
    @track newexistingsub;
    @track account;
    @track otherPaymentOptions = true;
    @track paymentMethods;
    @track paymentTypes;
    @track paymentMethod ='Credit Card';
    @track showcheck = false
    @track showpo = false
    @track showcc = true;
    bankaccounttype = 'checking';
    @track disablepay = true;
    @track hidePayment = false;
    @track paymentReponse;
    @track subReponse;
    @track currentDatetime;
    currentPageReference = null; 
    @track urlStateParameters;
    @track amount;
    @track hidePage = true;
    @track address = {};
    @track email;
    @api subscriptionmode = false;
    @api fieldapiname;
    @track singletimepaymentmode = true;
    @track showpaymenttyperadio = false;
    @track showonetimepayment = false;
    @track showrecurringpayment = false;
    @api objectapiname;
    @api overridepaymentamount = false;
    @api overrideproduct = false;
    @api readonlypaymentamount = false;
    @api readonlyproduct = false;
    @api readonlyepaymentamount = false;
    @api paymentserviceprovider;
    @track showexternalpaymentlink = false;
    @api showexternalpaymentlinksection = false;
    @api recordId;
    custom1;custom2;custom3;custom4;logourl;
  
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
      if (currentPageReference && this.recordId == undefined ) {
        this.urlStateParameters = currentPageReference.state;
      }
    }

    initUrlParams(){

      this.amount = this.urlStateParameters.amount;
      this.logourl = this.urlStateParameters.logourl;

      this.address.BillingStreet = this.urlStateParameters.street;
      this.address.BillingCity = this.urlStateParameters.city;
      //this.address.BillingStreet2 = this.urlStateParameters.address2;
      this.address.BillingState = this.urlStateParameters.state;
      this.address.BillingPostalCode = this.urlStateParameters.zip;
      this.address.BillingCountry = this.urlStateParameters.country;
      if(this.urlStateParameters.country == undefined){
        this.address.BillingCountry = 'USA';
      }
      this.email = this.urlStateParameters.email;
      this.firstname = this.urlStateParameters.firstname;
      this.lastname = this.urlStateParameters.lastname;
      this.address.internationalAddress = false;
      this.paymentdetail.addressdetails = this.address;
      //Custom
      this.custom1 = this.urlStateParameters.custom1;
      this.custom2 = this.urlStateParameters.custom2;
      this.custom3 = this.urlStateParameters.custom3;
      this.custom4 = this.urlStateParameters.custom4;

      this.isLoaded = !this.isLoaded;
      this.hidePage = false;
      //this.getSubscriptions();
    }

    @track showExistingSubcription = false;
    @track showNewSubcription = true;
    @track showpaywith = true;
    handleSubcriptionActions(event){

        const selectedOption = event.detail.value;
        this.processSubscriptionActions(selectedOption);
      
    }

    processSubscriptionActions(selectedOption){
      if(selectedOption == 'New Subscription'){
        this.showNewSubcription = true;
        this.showExistingSubcription = false;
        this.showsubedit = false;
        this.showNewSubcription = true;

        /*this.occurrances = 1;
        this.unit = 'Monthly';
        this.startdate = new Date().toISOString().split('T')[0];

        this.subname = '';
        this.amount = 0;*/
        this.showpaywith = true;
        this.newexistingsub = 'New Subscription';

      }else if(selectedOption == 'Existing Subscriptions'){
        this.showNewSubcription = false;
        this.showExistingSubcription = true;
        this.showpaywith = false;
        this.newexistingsub = 'Existing Subscriptions';

        this.getSubscriptions();
      }

      console.log('Option selected with value: ' + selectedOption);
    }

    @track firstname;
    @track lastname;
    @track subscriptionOptions;
    connectedCallback() {
      this.isLoaded = !this.isLoaded;
      if(this.subscriptionmode && this.singletimepaymentmode){
        this.showpaymenttyperadio = true;
      }
      if(this.singletimepaymentmode){
        this.showonetimepayment = true;
      }

      console.log("recordId", this.recordId);
      console.log("paymentserviceprovider", this.paymentserviceprovider);
      this.account = {BillingCountry:"USA", BillingCity:"", BillingState:"", BillingPostalCode:"", BillingStreet:""};
      this.paymentMethods = [{'label': 'Credit Card', 'value': 'Credit Card', selected: true},
      {'label': 'eCheck', 'value': 'eCheck'}]
      this.paymentTypes = [{'label': 'One Time', 'value': 'One Time', selected: true},
      {'label': 'Recurring', 'value': 'Recurring'}]

      this.subscriptionOptions = [{'label': 'New Subscription', 'value': 'New Subscription'},
      {'label': 'Existing Subscriptions', 'value': 'Existing Subscriptions'}]
      

      this.paymentdetail = {
        carddetails : {},
        addressdetails : {},
        otherdetails : {},
        bankdetails : {} ,
        subdetails : {} 
      };
      if(this.urlStateParameters != undefined && this.urlStateParameters != null){

        if(this.urlStateParameters.data != null && this.urlStateParameters.data != undefined){
          decryptURL({ encryptedData: this.urlStateParameters.data, sobjectAPIName : this.objectapiname, paymentserviceprovider : this.paymentserviceprovider})
          .then((result) => {
              this.urlStateParameters = result;
              this.initUrlParams();

            })
          .catch((error) => {
            this.hidePage = true;
            console.log('Error===>', error);
            let message = '';
            if(error.message == undefined){
              message = error.body.message + ' ' + error.body.stackTrace;
            }else{
              message = error.name + ' ' +error.message+' ' +error.stack
            }
            const event = new ShowToastEvent({
              title: 'Payment Response',
              message: message,
              variant: 'error',
              mode: 'dismissable'
          });
          this.dispatchEvent(event);
              this.error = error;
              this.contacts = undefined;
              this.isLoaded = !this.isLoaded;
          });
      }else{
        this.initUrlParams();

      }


      }else{
        retrieveRecord({ recordId: this.recordId, sobjectAPIName : this.objectapiname, paymentserviceprovider : this.paymentserviceprovider})
        .then((result) => {
            this.urlStateParameters = result;
            this.initUrlParams();

          })
        .catch((error) => {
          console.log('Error===>', error);
          let message = '';
          if(error.message == undefined){
            message = error.body.message + ' ' + error.body.stackTrace;
          }else{
            message = error.name + ' ' +error.message+' ' +error.stack
          }
          const event = new ShowToastEvent({
            title: 'Payment Response',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
            this.error = error;
            this.contacts = undefined;
            this.isLoaded = !this.isLoaded;
        });


      }

    }
    
    get accountTypes() {
      return [
          { label: 'Personal Checking', value: 'checking', selected : true},
          { label: 'Personal Savings', value: 'savings' },
          { label: 'Business Checking', value: 'businessChecking' },
      ];
  }

  @track bankname;
  @track accountnumber;
  @track accountfirstname;
  @track accountlastname;
  @track routingnumber;
  @track accountnumber;

  onchangerbankname(event){
    this.bankname = event.detail.value;
    if(this.getIsValid() && (this.addressvalid || this.subvalid)){
      this.disablepay = false;
    }else{
      this.disablepay = true;
    }
  }

  //@track bankaccounttype;
  handleAccountTypeChange(event) {
    this.bankaccounttype = event.detail.value;
    if(this.getIsValid() && (this.addressvalid || this.subvalid)){
      this.disablepay = false;
    }else{
      this.disablepay = true;
    }
}

handleamount(event) {
  this.urlStateParameters.amount = parseFloat(event.detail.value);
}

handleproduct(event) {
  this.urlStateParameters.product = event.detail.value;

}

onchangeaccountname(event){
  this.accountname = event.detail.value;
  if(this.getIsValid() && (this.addressvalid || this.subvalid)){
    this.disablepay = false;
  }else{
    this.disablepay = true;
  }

}


onchangeaccountnumber(event){
  this.accountnumber = event.detail.value;
  if(this.getIsValid() && (this.addressvalid || this.subvalid)){
    this.disablepay = false;
  }else{
    this.disablepay = true;
  }
}

handleDoneAction(){
    

}

onchangeroutingnumber(event) {
  let inputVal = event.target.value;
  if(!isFinite(inputVal)) {
      event.target.value = inputVal.toString().slice(0,-1);
  }
  this.routingnumber = event.detail.value;
  if(this.getIsValid() && (this.addressvalid || this.subvalid)){
    this.disablepay = false;
  }else{
    this.disablepay = true;
  }
}

getIsValid(){

  if(this.bankname != undefined && this.accountnumber != undefined && this.accountname != undefined && this.routingnumber != undefined && this.bankname != "" && this.accountnumber != "" && this.accountname != "" && this.routingnumber != ""  ){
    return true
  }
  return false;
};


    handlePaymentMethodChange(event) {
      const selectedOption = event.detail.value;
      if(selectedOption == 'Credit Card'){
        this.showcc = true;
        this.showcheck = false;
        this.disablepay = true;

      }else if(selectedOption == 'eCheck'){
        this.showcheck = true;
        this.showcc = false;
        this.bankname = null;
        this.accountnumber = null;
        this.accountname = null;
        this.accountlastname = null;
        this.accountnumber = null;
        this.routingnumber = null;
      }
      this.disablepay = true;

      console.log('Option selected with value: ' + selectedOption);
  }

  handlePaymentTypeChange(event) {
    const selectedOption = event.detail.value;
    if(selectedOption == 'Recurring'){
      this.showonetimepayment = false;

      this.showrecurringpayment = true;
      this.newexistingsub = 'New Subscription';
    }else if(selectedOption == 'One Time'){
      this.showonetimepayment = true;
      this.showrecurringpayment = false;

    }
    console.log('Option selected with value: ' + selectedOption);
}

    get stateOptions() {
        return [
          { value: 'Select a State', label: '' },
          { value: 'AL', label: 'Alabama' },
          { value: 'AK', label: 'Alaska' },
          { value: 'AZ', label: 'Arizona' },
          { value: 'AR', label: 'Arkansas' },
          { value: 'CA', label: 'California' },
          { value: 'CO', label: 'Colorado' },
          { value: 'CT', label: 'Connecticut' },
          { value: 'DE', label: 'Delaware' },
          { value: 'DC', label: 'District Of Columbia' },
          { value: 'FL', label: 'Florida' },
          { value: 'GA', label: 'Georgia' },
          { value: 'HI', label: 'Hawaii' },
          { value: 'ID', label: 'Idaho' },
          { value: 'IL', label: 'Illinois' },
          { value: 'IN', label: 'Indiana' },
          { value: 'IA', label: 'Iowa' },
          { value: 'KS', label: 'Kansas' },
          { value: 'KY', label: 'Kentucky' },
          { value: 'LA', label: 'Louisiana' },
          { value: 'ME', label: 'Maine' },
          { value: 'MD', label: 'Maryland' },
          { value: 'MA', label: 'Massachusetts' },
          { value: 'MI', label: 'Michigan' },
          { value: 'MN', label: 'Minnesota' },
          { value: 'MS', label: 'Mississippi' },
          { value: 'MO', label: 'Missouri' },
          { value: 'MT', label: 'Montana' },
          { value: 'NE', label: 'Nebraska' },
          { value: 'NV', label: 'Nevada' },
          { value: 'NH', label: 'New Hampshire' },
          { value: 'NJ', label: 'New Jersey' },
          { value: 'NM', label: 'New Mexico' },
          { value: 'NY', label: 'New York' },
          { value: 'NC', label: 'North Carolina' },
          { value: 'ND', label: 'North Dakota' },
          { value: 'OH', label: 'Ohio' },
          { value: 'OK', label: 'Oklahoma' },
          { value: 'OR', label: 'Oregon' },
          { value: 'PA', label: 'Pennsylvania' },
          { value: 'RI', label: 'Rhode Island' },
          { value: 'SC', label: 'South Carolina' },
          { value: 'SD', label: 'South Dakota' },
          { value: 'TN', label: 'Tennessee' },
          { value: 'TX', label: 'Texas' },
          { value: 'UT', label: 'Utah' },
          { value: 'VT', label: 'Vermont' },
          { value: 'VA', label: 'Virginia' },
          { value: 'WA', label: 'Washington' },
          { value: 'WV', label: 'West Virginia' },
          { value: 'WI', label: 'Wisconsin' },
          { value: 'WY', label: 'Wyoming' }
        ];
      }
      @track addressvalid = false;
      @track cardvalid = false;
      handleAddressValid(event){
        this.addressvalid = true;
        if(this.showcc){
          if(this.cardvalid){
            this.disablepay = false;
          }
        }else{
          if(this.getIsValid() && (this.addressvalid || this.subvalid)){
            this.disablepay = false;
          }
        }
        
        this.paymentdetail.addressdetails= event.detail.value;

      }

      @track subvalid = false;
      @track showdonebutton = false;
      
      handleSubscriptionComplete(event){
        
        if((this.cardvalid)){
          this.disablepay = false;
        }else{
          this.disablepay = true;

        }

        this.paymentdetail.subdetails= event.detail.value;
        this.subvalid = true;

      }
      
      handleAddressInvalid(event){
        this.addressvalid = false;
        this.disablepay = true;
      }

      handleCardComplete(event){
        this.cardvalid = true;
        if((this.addressvalid || this.subvalid)){

          if(this.showrecurringpayment){
            if(this.subvalid){
              this.disablepay = false;
            }else{
              this.disablepay = true;
            }
          }else{
            this.disablepay = false;
          }

          if(this.selectedrow != null && this.selectedrow.id != null){
            this.disablepay = false;
          }

        }
        this.paymentdetail.carddetails  = event.detail.value;
    
      }

      handleCardIncomplete(event){
        this.cardvalid = false;
        this.disablepay = true;
      }

      handleSubIncomplete(event){
        this.subvalid = false;
        this.disablepay = true;
      }
      
      handleSub(){
        this.isLoaded = !this.isLoaded;
        console.log('Handle Sub' , this.recordId);
        //if(this.recordId == undefined){
          let otherDetails = {
            product: this.urlStateParameters.product,
            amount: this.urlStateParameters.amount,
            refid: this.urlStateParameters.refid,
            fieldapiname: this.urlStateParameters.fieldapiname,
            objectapiname: this.urlStateParameters.objectapiname,
            paymentserviceprovider:this.paymentserviceprovider
          }
          this.paymentdetail.otherdetails = otherDetails;
        /*}else{
          let otherDetails = {
            product: 'Test',
            amount: 32,
            refid: this.recordId,
            fieldapiname: this.fieldapiname, 
            objectapiname:this.urlStateParameters.objectapiname
          }
          this.paymentdetail.otherdetails = otherDetails;
        }*/
        if(this.showcheck){
          let bankdetails = {
            accountType: this.bankaccounttype,
            routingNumber: this.routingnumber,
            accountNumber: this.accountnumber,
            nameOnAccount: this.accountname,
          }
          this.paymentdetail.bankdetails = bankdetails;

        }
        //this.paymentdetail.subDetails = this.subDetails;

        createSubscription({ paymentData: JSON.stringify(this.paymentdetail)})
        .then((result) => {
          if(result.success){
              const event = new ShowToastEvent({
                title: 'Payment Response',
                message: 'Your payment was processed succssfully. Thank you.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.error = undefined;
            this.hidePayment = true;
            this.subReponse = result;
            this.currentDatetime = new Date();
            this.showdonebutton = true;
            this.showpaymenttyperadio = false;

          }else{
            const event = new ShowToastEvent({
              title: 'Error',
              message: result.responseText,
              variant: 'error',
              mode: 'dismissable'
          });
          this.dispatchEvent(event);
          }
          this.isLoaded = !this.isLoaded;
        })
        .catch((error) => {
          console.log('Error===>', error);
          let message = '';
          if(error.message == undefined){
            message = error.body.message + ' ' + error.body.stackTrace;
          }else{
            message = error.name + ' ' +error.message+' ' +error.stack
          }
          const event = new ShowToastEvent({
            title: 'Payment Response',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
            this.error = error;
            this.contacts = undefined;
            this.isLoaded = !this.isLoaded;
        });
        

      }


      editSub(){
        this.isLoaded = !this.isLoaded;
        let otherDetails = {
          //product: this.urlStateParameters.product,
          //amount: this.urlStateParameters.amount,
          paymentserviceprovider:this.paymentserviceprovider,
          refid: this.urlStateParameters.refid,
          fieldapiname: this.urlStateParameters.fieldapiname,
          objectapiname: this.urlStateParameters.objectapiname,
          subscriptionId: (this.selectedrow ? this.selectedrow.id : null),
          trackPaySubscriptionId : (this.selectedrow ? this.selectedrow.trackPaySubscriptionId : null)
        }
        this.paymentdetail.otherdetails = otherDetails;
        if(this.showcheck){
          let bankdetails = {
            accountType: this.bankaccounttype,
            routingNumber: this.routingnumber,
            accountNumber: this.accountnumber,
            nameOnAccount: this.accountname,
          }
          this.paymentdetail.bankdetails = bankdetails;

        }
        //this.paymentdetail.subDetails = this.subDetails;

        updateSubscription({ paymentData: JSON.stringify(this.paymentdetail)})
        .then((result) => {
          if(result.success){
              const event = new ShowToastEvent({
                title: 'Payment Response',
                message: 'Your payment was processed succssfully. Thank you.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.error = undefined;
            this.hidePayment = true;
            this.subReponse = result;
            this.currentDatetime = new Date();
            this.showdonebutton = true;
            this.showpaymenttyperadio = false;

          }else{
            const event = new ShowToastEvent({
              title: 'Error',
              message: result.responseText,
              variant: 'error',
              mode: 'dismissable'
          });
          this.dispatchEvent(event);
          }
          this.isLoaded = !this.isLoaded;
        })
        .catch((error) => {
          console.log('Error===>', error);
          let message = '';
          if(error.message == undefined){
            message = error.body.message + ' ' + error.body.stackTrace;
          }else{
            message = error.name + ' ' +error.message+' ' +error.stack
          }
          const event = new ShowToastEvent({
            title: 'Payment Response',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
            this.error = error;
            this.contacts = undefined;
            this.isLoaded = !this.isLoaded;
        });
        

      }

      @track subscriptiondata;
      getSubscriptions(){
        this.isLoaded = !this.isLoaded;
        this.paymentdetail = {
          carddetails : {},
          addressdetails : {},
          otherdetails : {},
          bankdetails : {} ,
          subdetails : {} 
        };
  
        let otherDetails = {
          paymentserviceprovider:this.paymentserviceprovider,
          product: this.urlStateParameters.product,
          amount: this.urlStateParameters.amount,
          refid: this.urlStateParameters.refid,
          fieldapiname: this.urlStateParameters.fieldapiname,
          objectapiname: this.urlStateParameters.objectapiname

        }
        this.paymentdetail.otherdetails = otherDetails;


        getSubscriptions({ paymentData: JSON.stringify(this.paymentdetail) })
        .then((result) => {
          this.subscriptiondata = result.subscriptionDetails;
          this.isLoaded = !this.isLoaded;
        })
        .catch((error) => {
          console.log('Error===>', error);
          let message = '';
          if(error.message == undefined){
            message = error.body.message + ' ' + error.body.stackTrace;
          }else{
            message = error.name + ' ' +error.message+' ' +error.stack
          }
          const event = new ShowToastEvent({
            title: 'Payment Response',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
            this.error = error;
            this.contacts = undefined;
            this.isLoaded = !this.isLoaded;
        });
        
      }

      handlePay(){
        if(!this.urlStateParameters.amount || !this.urlStateParameters.product){
            const event = new ShowToastEvent({
              title: 'Payment Response',
              message: 'Amount or Product is missind',
              variant: 'error',
              mode: 'dismissable'
          });
          this.dispatchEvent(event);
          return;
        }

        this.isLoaded = !this.isLoaded;
        this.disablepay = true;
        let otherDetails = {
          paymentserviceprovider:this.paymentserviceprovider,
          product: this.urlStateParameters.product,
          amount: this.urlStateParameters.amount,
          refid: this.urlStateParameters.refid,
          fieldapiname: this.urlStateParameters.fieldapiname,
          objectapiname: this.urlStateParameters.objectapiname,
          custom1: this.urlStateParameters.custom1,
          custom2: this.urlStateParameters.custom2,
          custom3: this.urlStateParameters.custom3,
          custom4: this.urlStateParameters.custom4,
          transactionkey: this.urlStateParameters.transactionkey
        }
        if(this.showcheck){
          let bankdetails = {
            accountType: this.bankaccounttype,
            routingNumber: this.routingnumber,
            accountNumber: this.accountnumber,
            nameOnAccount: this.accountname,
          }
          this.paymentdetail.bankdetails = bankdetails;

        }
        this.paymentdetail.otherdetails = otherDetails;

        chargeTransaction({ paymentData: JSON.stringify(this.paymentdetail) })
        .then((result) => {
          if(result.success){
              const event = new ShowToastEvent({
                title: 'Payment Response',
                message: 'Your payment was processed succssfully. Thank you.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.error = undefined;
            this.hidePayment = true;
            this.paymentReponse = result;
            this.currentDatetime = new Date();
            this.showdonebutton = true;
            this.showpaymenttyperadio = false;
            this.readonlyproduct = true;
            this.readonlyproduct = true;
            this.readonlypaymentamount = true;

          }else{
            const event = new ShowToastEvent({
              title: 'Error',
              message: result.responseText,
              variant: 'error',
              mode: 'dismissable'
          });
          this.dispatchEvent(event);
          this.disablepay = false;

          }
          this.isLoaded = !this.isLoaded;
        })
        .catch((error) => {
          console.log('Error===>', error);
          let message = '';
          if(error.message == undefined){
            message = error.body.message + ' ' + error.body.stackTrace;
          }else{
            message = error.name + ' ' +error.message+' ' +error.stack
          }
          const event = new ShowToastEvent({
            title: 'Payment Response',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
            this.error = error;
            this.contacts = undefined;
            this.isLoaded = !this.isLoaded;
            this.disablepay = false;

        });
        


      }

      handleCancel(event){

        if(this.showsubedit){
          this.showsubedit = false;
          this.processSubscriptionActions('Existing Subscriptions');
        }else{
          if(this.urlStateParameters.returl && this.urlStateParameters.returl != ''){
            window.open(this.urlStateParameters.returl, "_self");
          }else{
            location.reload();
          }

        }
  
      }


      @track columns = [
        { label: 'Id', fieldName: 'id' },
        { label: 'Name', fieldName: 'name' },
        { label: 'Createddate', fieldName: 'createTimeStampUTC' },
        //{ label: 'First Name', fieldName: 'firstName' },
        //{ label: 'Last Name', fieldName: 'lastName' },
        { label: 'Total Occurrences', fieldName: 'totalOccurrences' },
        //{ label: 'pastOccurrences', fieldName: 'pastOccurrences' },
        //{ label: 'Payment Method', fieldName: 'paymentMethod' },
        { label: 'Account Number', fieldName: 'accountNumber' },
        { label: 'Amount', fieldName: 'amount' },
        { label: 'Status', fieldName: 'status' },
        {
          type: 'action',
          typeAttributes: { rowActions: actions },
        }
    ];

    cancelSubAction(){
      this.isLoaded = !this.isLoaded;
      this.paymentdetail = {
        carddetails : {},
        addressdetails : {},
        otherdetails : {},
        bankdetails : {} ,
        subdetails : {} 
      };

      let otherDetails = {
        paymentserviceprovider:this.paymentserviceprovider,
        product: this.urlStateParameters.product,
        amount: this.urlStateParameters.amount,
        refid: this.urlStateParameters.refid,
        fieldapiname: this.urlStateParameters.fieldapiname,
        objectapiname: this.urlStateParameters.objectapiname,
        subscriptionId:this.selectedrow.id,
        trackPaySubscriptionId : (this.selectedrow ? this.selectedrow.trackPaySubscriptionId : null)

      }
      this.paymentdetail.otherdetails = otherDetails;


      cancelSubscription({ paymentData: JSON.stringify(this.paymentdetail)})
      .then((result) => {
        if(result.success){
          this.subscriptiondata = null;
          const event = new ShowToastEvent({
            title: 'Subscription',
            message: 'Subscription cancelled successfully.',
            variant: 'success',
            mode: 'dismissable'
          });
          this.dispatchEvent(event);
          this.newexistingsub = undefined;
          this.newexistingsub = 'New Subscription';
          this.processSubscriptionActions('New Subscription');

          this.getSubscriptions();


        }else{

          const event = new ShowToastEvent({
            title: 'Error',
            message: result.responseText,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);


        }


        this.showconfirmationpopup = false;

        this.isLoaded = !this.isLoaded;
      })
      .catch((error) => {
        console.log('Error===>', error);
        let message = '';
        if(error.message == undefined){
          message = error.body.message + ' ' + error.body.stackTrace;
        }else{
          message = error.name + ' ' +error.message+' ' +error.stack
        }
        const event = new ShowToastEvent({
          title: 'Payment Response',
          message: message,
          variant: 'error',
          mode: 'dismissable'
      });
      this.dispatchEvent(event);
          this.error = error;
          this.contacts = undefined;
          this.isLoaded = !this.isLoaded;
      });
    }

    confirmationPopupCancelAction(){
      this.showconfirmationpopup = false;

    }
    @track showconfirmationpopup = false;
    @track showsubedit = false;
    @track selectedrow;

    @track occurrances = 1;
    @track unit = 'Monthly';
    @track startdate = new Date().toISOString().split('T')[0];
    @track subname = '';
    @track amount = 0;

    handleRowAction( event ) {

      const actionName = event.detail.action.name;
      this.selectedrow= event.detail.row;
      switch ( actionName ) {
          case 'edit':
            this.showsubedit = true;
            this.showNewSubcription = true;
            this.showExistingSubcription = false;
            this.subname = this.selectedrow.name;
            this.unit = this.selectedrow.unit;
            this.startdate = this.selectedrow.createTimeStampUTC.split('T')[0];
            this.occurrances = this.selectedrow.totalOccurrences;
            this.amount = this.selectedrow.amount;
            this.showpaywith = true;

              break;
          case 'cancel':
            this.showconfirmationpopup = true;
            //this.cancelSubAction();
            break;
          default:
      }

  }

  handleExternalPaymentLink(event){
    this.showexternalpaymentlink = event.target.checked;


  }

}
const actions = [
  { label: 'Edit', name: 'edit' },
  { label: 'Cancel', name: 'cancel' },
];