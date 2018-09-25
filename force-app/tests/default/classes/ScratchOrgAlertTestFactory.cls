public with sharing class ScratchOrgAlertTestFactory {
    
    public static User configureUser(String email, Integer days_before, String additional_emails) {
        User CurrentUser = [select Id, ScratchOrgAlertRecipient__c, ScratchOrgAlertNotificationDays__c
                           from User where Id=:UserInfo.getUserId()];
        CurrentUser.ScratchOrgAlertRecipient__c = email;
        CurrentUser.ScratchOrgAlertNotificationDays__c = days_before;
        update CurrentUser;
        return CurrentUser;
    }

    public static User configureUser(String email, Integer days_before) {
        return configureUser(email, days_before, null);
    }

    public static List<ActiveScratchOrg> populateOrgs() {
        List<ActiveScratchOrg> orgs = new List<ActiveScratchOrg>();

        for(Integer i = 0; i < 5; i++) {
            orgs.add(new ActiveScratchOrg(OwnerId=UserInfo.getUserId()));
        }
        upsert(orgs);
        return orgs;
    }
}