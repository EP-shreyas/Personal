({
    doInit : function(component, event, helper){

        var pageReference = component.get("v.pageReference");
        /* Added By Priti Chande(16/05/2023)- to Check is it desktop/Mobile*/
        var device = $A.get("$Browser.formFactor");
        
        if(device === 'DESKTOP'){
                        component.set("v.deviceName",device);

            component.set("v.supportsPopOut",true);
        }else{
                        component.set("v.deviceName",device);

            component.set("v.supportsPopOut",false);
        }//Ended here Added By Priti Chande(16/05/2023)
        if(pageReference!== undefined && pageReference !==null && pageReference.state !=null)
        {
            var recordId=pageReference.state.c__recordId;
            var documentType=pageReference.state.c__documentType; 
            var sObjectName=pageReference.state.c__sObjectName; 

            component.set("v.recordId",recordId);
            component.set("v.documentType",documentType);
            component.set("v.isModalOpen", true);
            component.set("v.sObjectName", sObjectName);
            /*     var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();*/
            
            //Do whatever we want to do with record id 
        }else{ /* Added By Priti Chande(16/05/2023)- to get Task realted recordId */

          var recordId=component.get("v.recordId");
          var action = component.get("c.getRecordIdOnTaskObject");
       action.setParams({
          recordId: component.get("v.recordId")
          });
            action.setCallback(this, function(response) {
            
            var responseValue = response.getReturnValue(); 
            component.set("v.recordId",responseValue);
            
        });
        
        // Enqueue Action
        $A.enqueueAction(action);


            
        }
    },
    
    handleDestroy : function (component, event, helper) {
        var val = event.getParam("value");
        // Do something else here
        var action = component.get("c.clearData");
        action.setParams({ 
            recordId : component.get("v.recordId") 
        });
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned 
                // from the server
                console.log("From server: " + response.getReturnValue());
                
                // You would typically fire a event here to trigger 
                // client-side notification that the server-side 
                // action is complete
            }
        });
        $A.enqueueAction(action);
    }
    
    
    /* closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
       var navService = component.find("navigation")
    var pageReference = {
        "type" : "standard__recordPage",
        "attributes": {
            "recordId"      : component.get("v.recordId"),
            "actionName"    : "view"   //clone, edit, view
        }
    };
        navService.navigate(pageReference);
              $A.get("e.force:refreshView").fire();



    },*/
    
})