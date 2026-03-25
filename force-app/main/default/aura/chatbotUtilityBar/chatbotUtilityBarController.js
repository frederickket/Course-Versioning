({
    doInit: function (component, event, helper) {
        let action = component.get("c.getObjectApiName");
        let recordId = component.get("v.recordId")
        if(!recordId){
            component.set("v.sObjectName", '');
            return;
        }
        action.setParams({ "recordId": recordId });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                let name = JSON.parse(JSON.stringify(result)).responseData;
                component.set("v.sObjectName", name);
            } else if (state === "ERROR") {
                console.error("Error occurred: " + JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
    }
})