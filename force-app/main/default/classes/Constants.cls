public with sharing class Constants {
    public static final String ACTION_STATUS = 'Completed';
    public static final String INTERACTION_USER_PARTICIPANT = 'Participant';
    public static final String INTERACTION_TYPE_MEETING = 'Meeting';
    public static final String INTERACTION_TYPE_VIRTUAL_MEETING = 'Virtual Meeting';
    public static final String INTERACTION_TYPE_BOARD_MEETING = 'Board Meeting';//Aded by Priti chande(06/06/2023)
    public static final String INTERACTION_TYPE_IC_MEETING = 'IC Meeting';//Aded by Priti chande(06/06/2023)
    public static final String INTERACTION_TYPE_VISIT = 'Visit';
    public static final String INTERACTION_TYPE_SMI = 'Send Meeting Invite';
    public static final String INTER_MEET_INVIT_TEMPLATE = 'Interaction_Meeting_Invitation';
    public static final String INTER_EMAIL_TEMPLATE = 'Interaction_Email_Template';
    public static final String INTER_EMAIL_TEMPLATE_VISIT = 'Interaction_email_notification_For_Visit';//Added by Priti Chande(31/05/02023) - Visit Interaction Type there is Different Template
    public static final String OPPORTUNITY_DUPLICATE_ERROR_MSG_FOR_ACCOUNT = 'Opportunity Already Exists';
    public static final String OPPORTUNITY_STAGE_NAME_FOR_DEAL = 'Internal Approvals';//Aded by Priti chande(12/05/2023)
    public static final String CPCS_DUPLICATE_ERROR_MSG = 'CP/CS Record Already Exists';
    public static final String FILE_DELETE_ERROR_MSG = 'You can not delete this file as it is already submitted for approval.';//Added by Priti Chande(23/03/23)- to file error msg.
       public static final String WAIVER_TYPE_CP_WAIVER = 'CP Waiver';
    public static final String STATUS_WAIVED_OFF = 'Waived Off';
    public static final String WAIVER_TYPE_CONV_TO_CS = 'Convert to CS';
    public static final String CONDITION_TYPE_CS = 'CS';
    public static final String WAIVER_TYPE_CP_REVISION = 'CP Revision';
 /*   public void ProcessData () {
        System.debug ('-------Inside Update Handler-------');    
    }
    public void callingApex () {
        System.debug ('-------Logic Inside-------');    
    }*/
   
}