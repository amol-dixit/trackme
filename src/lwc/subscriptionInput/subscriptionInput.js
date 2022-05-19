import { LightningElement, track, api} from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class SubscriptionInput extends NavigationMixin(LightningElement)  {
    @track validate =false;
    @api occurrances = 1;
    @api unit = 'Monthly';
    @api startdate;
    @api subname = '';
    @api amount = 0;
    @api subdata;
    @api readonlymode = false;
    
    connectedCallback(){
        /*if(!this.startdate){
            this.startdate = new Date();
        }*/
    }

    unitoptions = [
        {value: 'Select', label: 'Select'},
        {value: 'Monthly', label: 'Monthly'},
        {value: 'Weekly', label: 'Weekly'},
    ];

    handleAmount(event){
        this.amount = event.target.value;

    }
    handleOccurr(event){
        this.occurrances = event.target.value;
        this.validateData();
    }

    handleUnit(event){
        this.unit = event.target.value;
        this.validateData();
    }

    handleStartDate(event){
        this.startdate = event.target.value;
        this.validateData();
    }

    handleSubName(event){
        this.subname = event.target.value;
        this.validateData();
    }

    validateData(){
        if(this.subname != null && this.startdate != null && this.amount != null && this.unit != null && this.occurrances != null && 
            this.unit != 'Select' && 
            this.subname != '' && this.startdate != '' && this.amount != '' && this.unit != '' && this.occurrances != '' ){
            this.validate = true;
            this.subscriptionDataCompleteEvent();
        }else{
            this.validate = false;
            this.subscriptionDataInCompleteEvent();
        }
        console.log('Validation', this.validate);
    }

    subscriptionDataCompleteEvent() {
        //send a message
        const detail = {
            type: "subscriptioncomplete",
            value: {
                subname: this.subname,
                startdate: this.startdate,
                occurrances: this.occurrances,
                amount : this.amount,
                unit: this.unit
            }
        };
        const changeEvent = new CustomEvent("subscriptioncomplete", { detail: detail });
        this.dispatchEvent(changeEvent);
    }

    subscriptionDataInCompleteEvent() {
        //send a message
        const detail = {
            type: "subscriptionIncomplete",
            value: {
                subname: this.subname,
                startdate: this.startdate,
                occurrances: this.occurrances,
                amount : this.amount,
                unit: this.unit
            }
        };
        const changeEvent = new CustomEvent("subscriptionincomplete", { detail: detail });
        this.dispatchEvent(changeEvent);
    }
}