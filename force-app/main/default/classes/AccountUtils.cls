public class AccountUtils {
    public static List<Account> accountsByState(String state){
        List<Account> accountMap = new List<Account>([SELECT Id, Name FROM Account where BillingState=:state]);
        return accountMap;
    }
}