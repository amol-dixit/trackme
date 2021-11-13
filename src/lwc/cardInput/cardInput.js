/* eslint-disable no-debugger */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track, api } from "lwc";
import { Card } from "./card";
import { Payment } from "./payment";

export default class CardInput extends LightningElement {
  @api paymentMethod = "Credit Card";
  @track paymentOptions = [
    { label: "Credit Card", value: "Credit Card", selected: true },
    { label: "Purchase Order", value: "Purchase Order" },
    { label: "Check", value: "Check" }
  ];

  set initcmp(value){
    this.cardEmailValid = this.getIsValid(this.cardEmail, "cardEmail");

  }

  @track card;

  @track valid = false;
  @track cardNumberValid = false;
  @track cardEmailValid = false;
  @track cardHolderNameValid = false;
  @track cardHolderFirstNameValid = false;
  @track cardHolderLastNameValid = false;
  @track cardExpiryValid = false;
  @api cardHolderFirstName;
  @api cardHolderLastName;

  @track cardNumberTouched = false;
  @track cardEmailTouched = false;
  @track cardHolderNameTouched = false;
  @track cardHolderFirstNameTouched = false;
  @track cardHolderLastNameTouched = false;
  @track cardExpiryTouched = false;
  @track cardCVCTouched = false;

  @track cardNumber = "";
  @track cardHolderName = "";
  @track cardExpiry = "";
  @track cardCVC = "";
  @api cardEmail = "";

  connectedCallback() {
    //copy public attributes to private ones
    var self = this;
    //debugger;
    window.setTimeout(() => {
      self.card = new Card({
        //reference to this object so will work with web components
        context: self,

        // a selector or DOM element for the form where users will
        // be entering their information
        form: self.template.querySelector(".cc-input"),
        // a selector or DOM element for the container
        // where you want the card to appear
        container: ".cc-wrapper", // *required*

        width: 250, // optional — default 350px
        formatting: true, // optional - default true

        // Strings for translation - optional
        messages: {
          validDate: "valid\ndate", // optional - default 'valid\nthru'
          monthYear: "mm/yyyy" // optional - default 'month/year'
        },

        // Default placeholders for rendered fields - optional
        placeholders: {
          number: "•••• •••• •••• ••••",
          name: "Full Name",
          firstname: "First Name",
          lastname: "Last Name",
          expiry: "••/••",
          cvc: "•••"
        },

        masks: {
          cardNumber: "•" // optional - mask card number
        },

        // if true, will log helpful messages for setting up Card
        debug: true // optional - default false
      });
    }, 50);
    console.log('this.cardEmail', this.cardEmail);
    this.cardHolderFirstNameValid = this.getIsValid(this.cardHolderFirstName, "cardHolderFirstName");
    this.cardHolderLastNameValid = this.getIsValid(this.cardHolderLastName, "cardHolderLastName");
    this.cardEmailValid = this.getIsValid(this.cardEmail, "cardEmail");


  }

  handleCCInput(event) {
    this.cardNumber = event.target.value;
    this.cardNumberValid = this.getIsValid(this.cardNumber, "cardNumber");
    this.cardNumberTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }

  handleNameInput(event) {
    /*this.cardHolderName = event.target.value;
    this.cardHolderNameValid = this.getIsValid(this.cardHolderName, "cardHolderName");
    this.cardHolderNameTouched = true;
    this.showFeedback();
    this.checkIfComplete();*/
  }
  handleFirstNameInput(event) {
    this.cardHolderFirstName = event.target.value;
    this.cardHolderFirstNameValid = this.getIsValid(this.cardHolderFirstName, "cardHolderFirstName");
    this.cardHolderFirstNameTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }

  handleEmailInput(event) {
    this.cardEmail= event.target.value;
    this.cardEmailValid = this.getIsValid(this.cardEmail, "cardEmail");
    this.cardEmailTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }

  handleLastNameInput(event) {
    this.cardHolderLastName = event.target.value;
    this.cardHolderLastNameValid = this.getIsValid(this.cardHolderLastName, "cardHolderLastName");
    this.cardHolderLastNameTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }

  handleExpiryInput(event) {
    this.cardExpiry = event.target.value;
    this.cardExpiryValid = this.getIsValid(this.cardExpiry, "cardExpiry");
    this.cardExpiryTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }
  handleCVVInput(event) {
    this.cardCVC = event.target.value;
    this.cardCVCValid = this.getIsValid(this.cardCVC, "cardCVC");
    this.cardCVCTouched = true;
    this.showFeedback();
    this.checkIfComplete();
  }

  showFeedback() {
    if (!this.cardNumberValid && this.cardNumberTouched) {
      //show error label
      this.template.querySelectorAll(".cardNumberError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardNumberFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardNumberError")[0].classList.add("slds-hide");
      this.template
        .querySelectorAll(".cardNumberFormElement")[0]
        .classList.remove("slds-has-error");
    }
    if (!this.cardEmailValid && this.cardEmailTouched) {
      //show error label
      this.template.querySelectorAll(".cardemailError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardemailFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardemailError")[0].classList.add("slds-hide");
      this.template
        .querySelectorAll(".cardemailFormElement")[0]
        .classList.remove("slds-has-error");
    }

    /*if (!this.cardHolderNameValid && this.cardHolderNameTouched) {
      //show error label
      this.template.querySelectorAll(".cardNameError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardNameFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardNameError")[0].classList.add("slds-hide");
      this.template.querySelectorAll(".cardNameFormElement")[0].classList.remove("slds-has-error");
    }*/

    if (!this.cardHolderFirstNameValid && this.cardHolderFirstNameTouched) {
      //show error label
      this.template.querySelectorAll(".cardFirstNameError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardFirstNameFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardFirstNameError")[0].classList.add("slds-hide");
      this.template.querySelectorAll(".cardFirstNameFormElement")[0].classList.remove("slds-has-error");
    }

    if (!this.cardHolderLastNameValid && this.cardHolderLastNameTouched) {
      //show error label
      this.template.querySelectorAll(".cardLastNameError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardLastNameFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardLastNameError")[0].classList.add("slds-hide");
      this.template.querySelectorAll(".cardLastNameFormElement")[0].classList.remove("slds-has-error");
    }

    if (!this.cardExpiryValid && this.cardExpiryTouched) {
      //show error label
      this.template.querySelectorAll(".cardExpiryError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardExpiryFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardExpiryError")[0].classList.add("slds-hide");
      this.template
        .querySelectorAll(".cardExpiryFormElement")[0]
        .classList.remove("slds-has-error");
    }

    if (!this.cardCVCValid && this.cardCVCTouched) {
      //show error label
      this.template.querySelectorAll(".cardCVVError")[0].classList.remove("slds-hide");
      this.template.querySelectorAll(".cardCVVFormElement")[0].classList.add("slds-has-error");
    } else {
      this.template.querySelectorAll(".cardCVVError")[0].classList.add("slds-hide");
      this.template.querySelectorAll(".cardCVVFormElement")[0].classList.remove("slds-has-error");
    }
  }

  //this syntax means we should be able to leave off 'this'
  checkIfComplete = () => {
    console.log(this.cardNumberValid,  this.cardHolderFirstNameValid, this.cardHolderLastNameValid, this.cardExpiryValid, this.cardCVCValid, this.cardEmailValid);
    if (
      this.cardNumberValid &&
      this.cardHolderFirstNameValid &&
      this.cardHolderLastNameValid &&
      this.cardExpiryValid &&
      this.cardCVCValid &&
      this.cardEmailValid
    ) {
      //send a message
      const detail = {
        type: "cardComplete",
        value: {
          cardNumber: this.cardNumber,
          //cardHolderName: this.cardHolderName,
          cardHolderLastName: this.cardHolderLastName,
          cardHolderFirstName: this.cardHolderFirstName,
          cardCVV: this.cardCVC,
          cardExpiry: this.cardExpiry,
          cardType: this.card.cardType,
          cardEmail: this.cardEmail
        }
      };
      this.dispatchCompleteEvent(detail);
    } else {
      this.dispatchIncompleteEvent();
    }
  };

  dispatchCompleteEvent(cardData) {
    console.log('cardData', cardData);
    const changeEvent = new CustomEvent("cardcomplete", { detail: cardData });
    this.dispatchEvent(changeEvent);
  }

  dispatchIncompleteEvent() {
    const changeEvent = new CustomEvent("cardincomplete", { detail: {} });
    this.dispatchEvent(changeEvent);
    console.log('cccc');
  }

  handlePaymentMethodChange(event) {
    const selectedMethod = event.detail.value;
    const changeEvent = new CustomEvent("paymentMethodChange", {
      detail: { paymentMethod: selectedMethod }
    });
    this.dispatchEvent(changeEvent);
  }

  
  getIsValid = (val, validatorName) => {

    var isValid, objVal;
    if (validatorName === "cardExpiry") {
      objVal = Payment.fns.cardExpiryVal(val);
      isValid = Payment.fns.validateCardExpiry(objVal.month, objVal.year);
    } else if (validatorName === "cardCVC") {
      isValid = Payment.fns.validateCardCVC(val, this.card.cardType);
    } else if (validatorName === "cardNumber") {
      isValid = Payment.fns.validateCardNumber(val);
    } else if (validatorName === "cardHolderName") {
      isValid = val !== "";
    }else if (validatorName === "cardHolderFirstName") {
      isValid = val !== "";
    }else if (validatorName === "cardHolderLastName") {
      isValid = val !== "";
    }else if (validatorName === "cardEmail") {
      //console.log('val', val, this.validateEmail(val));
      if(val){
        isValid = (val !== "" && this.validateEmail(val));
      }else{
        isValid = val !== "";
      }
    }
    //console.log('VALIDATOR', validatorName, val, isValid);
    
    return isValid;
  };

  validateEmail(email) {
      const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(String(email).toLowerCase());
  }

}