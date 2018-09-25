@isTest
public with sharing class ScratchOrgAlertEmailerTest {
    
    @isTest
    public static void testSendEmails() {
        Map<Id, List<ActiveScratchOrg>> notifiableOrgs = new Map<Id, List<ActiveScratchOrg>>();
        List<ActiveScratchOrg> orgList = new List<ActiveScratchOrg>();
        orgList.add(new ActiveScratchOrg(OwnerId=UserInfo.getUserId()));
        notifiableOrgs.put(UserInfo.getUserId(), orgList);
        System.assert(ScratchOrgAlert.emailOrgOwners(notifiableOrgs));
    }
}