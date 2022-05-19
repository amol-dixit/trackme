import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import VoidTransaction from '@salesforce/apex/ManagePaymentService.voidTransaction';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import VOIDED_FIELD from '@salesforce/schema/Payment__c.Voided__c';

export default class VoidPaymentQuickAction extends LightningElement {
    @api recordId;
    @api paymentResult;
    @api paymentdisabled = false;
    connectedCallback() {
        console.log("recordId", this.recordId);
    }
    /*@wire(getRecord, { recordId: this.recordId, fields: [VOIDED_FIELD] })
    payment;*/

    @api invoke() {
        
        VoidTransaction({ paymentId: this.recordId })
		.then(result => {
            this.paymentResult = result;
            if(result.success == true){
                const event = new ShowToastEvent({
                    title: 'Payment Response',
                    message: 'Payment voided successfully :: ' + result.message,
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);			
                this.error = undefined;
            }else{
                const event = new ShowToastEvent({
                    title: 'Payment Response',
                    message: 'Error while voiding the payment :: ' + result.message,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);			
                this.error = undefined;
            }
            this.paymentdisabled = true;

            getRecordNotifyChange([{recordId: this.recordId}]);

		})
		.catch(error => {
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
		})


      }
      closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
      }
      
}