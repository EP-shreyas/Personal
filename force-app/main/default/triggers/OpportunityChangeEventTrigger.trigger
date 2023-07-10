/**
 * @description       : 
 * @author            : Ishwari Gaikwad(Thinqloud)
 * @group             : 
 * @last modified on  : 01-26-2023
 * @last modified by  : Ishwari Gaikwad(Thinqloud)
**/
trigger OpportunityChangeEventTrigger on OpportunityChangeEvent (after insert) {
	EventAndActionHandler.identifyAndPublishEvent(Trigger.New,'Opportunity');   
}