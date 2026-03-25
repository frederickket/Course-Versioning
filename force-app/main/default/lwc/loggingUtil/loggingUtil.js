/**
 * @Author 		WDCi (Lean)
 * @Date 		Sept 2023
 * @group 		Util
 * @Description Logging utility for LWC
 * @changehistory
 * ISS-002434 30-04-2025 XiRouh - updated getErrorMessage() to handle different event structure
 */
import { LightningElement } from 'lwc';

const logInfo = (prefix, anything, isDebugMode, isJson) => {
    if (isDebugMode) {
        if (isJson) {
            console.log(prefix + ' :: ' + JSON.stringify(anything));
        } else {
            console.log(prefix + ' :: ' + anything);
        }
    }
}

const logError = (prefix, anything, isJson) => {
    if (isJson) {
        console.log(prefix + ' :: ' + JSON.stringify(anything));
    } else {
        console.log(prefix + ' :: ' + anything);
    }
}

const startTimer = (timerName, isDebugMode) => {
    if (isDebugMode) {
        console.time(timerName);
    }
}

const stopTimer = (timerName, isDebugMode) => {
    if (isDebugMode) {
        console.timeEnd(timerName);
    }
}

const getErrorMessage = (error) => {
    logError('loggingUtil', error, true);

    let message = 'Unknown error';
    if(error.body){
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
        } else if (typeof error.body.message === "string") {
            message = error.body.message;
        }
    } else if (error?.output) {
        let tempErrorMsg = '';

        if (Array.isArray(error.output?.errors) && error.output?.errors.length > 0) {
            tempErrorMsg += error.output.errors.map((e) => e.message).join(", ");

        } 
        
        if (error.output?.fieldErrors) {
            const fieldErrorMessages = [];

            Object.values(error.output.fieldErrors).forEach((fieldErrorArray) => {
                fieldErrorArray.forEach((fieldError) => {
                    if (fieldError?.message) {
                        fieldErrorMessages.push(fieldError.message);
                    }
                });
            });

            if (fieldErrorMessages.length > 0) {
                tempErrorMsg += fieldErrorMessages.join(", ");
            }
        }

        if (tempErrorMsg) {
            message = tempErrorMsg;
        }
        
    } else if (error.message){
        message = error.message;
    }
    
    return message;
}

export { getErrorMessage, logInfo, logError, startTimer, stopTimer };

export default class LoggingUtil extends LightningElement {}