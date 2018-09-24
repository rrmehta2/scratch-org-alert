trigger ScratchOrgAlertDaysChanged on User (after update) {
    List<User> users = new List<User>();
    for(Id id : Trigger.newMap.keySet()){
        User oldUserInfo = Trigger.oldMap.get(id);
        User newUserInfo = Trigger.newMap.get(id);
        if(newUserInfo.ScratchOrgAlertEnabled__c 
            && (oldUserInfo.ScratchOrgAlertRecipient__c != newUserInfo.ScratchOrgAlertRecipient__c
                || oldUserInfo.ScratchOrgAlertNotificationDays__c != newUserInfo.ScratchOrgAlertNotificationDays__c)) {
            users.add(Trigger.newMap.get(id));
        }
    }
    ScratchOrgAlert.run(users);
}