@isTest
public with sharing class ScratchOrgAlertSettingsControllerTest {
    
    @isTest
    public static void TestDefinedUser() {
        ScratchOrgAlertTestFactory.configureUser('test@test.com', 3);
        ScratchOrgAlertSettingsController nsc = new ScratchOrgAlertSettingsController();
        System.assertEquals('test@test.com', nsc.user.ScratchOrgAlertRecipient__c);
        System.assertEquals(3, nsc.user.ScratchOrgAlertNotificationDays__c);
    }

    @isTest
    public static void TestNullUser() {
        ScratchOrgAlertTestFactory.configureUser(null, null);
        ScratchOrgAlertSettingsController nsc = new ScratchOrgAlertSettingsController();
        System.assertEquals(UserInfo.getUserEmail(), nsc.user.ScratchOrgAlertRecipient__c);
        System.assertEquals(ScratchOrgAlertSettingsController.DEFAULT_DAYS_BEFORE, nsc.user.ScratchOrgAlertNotificationDays__c);
    }

    @isTest
    public static void TestSave() {
        ScratchOrgAlertTestFactory.configureUser(null, 3);
        ScratchOrgAlertSettingsController nsc = new ScratchOrgAlertSettingsController();
        nsc.user.ScratchOrgAlertRecipient__c = 'test@test.com';
        nsc.user.ScratchOrgAlertNotificationDays__c = 4;
        nsc.save();
        User CurrentUser = [select Id, ScratchOrgAlertRecipient__c, ScratchOrgAlertNotificationDays__c
                           from User where Id=:UserInfo.getUserId()];
        System.assertEquals('test@test.com', CurrentUser.ScratchOrgAlertRecipient__c);
        System.assertEquals(4, CurrentUser.ScratchOrgAlertNotificationDays__c);
    }

    @isTest
    public static void TestInvalidDaysBefore() {
        ScratchOrgAlertTestFactory.configureUser(null, 3, null);
        ScratchOrgAlertSettingsController nsc = new ScratchOrgAlertSettingsController();
        nsc.user.ScratchOrgAlertNotificationDays__c = -2;
        nsc.save();

        User CurrentUser = [select Id, ScratchOrgAlertNotificationDays__c
                           from User where Id=:UserInfo.getUserId()];
        System.assertEquals(3, CurrentUser.ScratchOrgAlertNotificationDays__c);
    }
}