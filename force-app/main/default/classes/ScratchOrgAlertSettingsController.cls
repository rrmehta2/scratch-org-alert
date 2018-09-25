public with sharing class ScratchOrgAlertSettingsController {
    
    public User user { get; set; }
    public Boolean jobEnabled { get; set; }
    public Boolean saveUserNotificationSettingsDisabled { get; set; }
    public static final Integer DEFAULT_DAYS_BEFORE = 1;

    public ScratchOrgAlertSettingsController() {
        if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.User, ScratchOrgAlert.UserQueryFields)) {
            Id currentUserId = UserInfo.getUserId();
            this.user = Database.query('SELECT ' + String.join(ScratchOrgAlert.UserQueryFields, ', ') + ' FROM User WHERE Id=:currentUserId LIMIT 1');

            // Set the defaults here because they're not working as defined in the custom field definitions
            if (user.ScratchOrgAlertEnabled__c == null) {
                user.ScratchOrgAlertEnabled__c = false;
            }

            if (user.ScratchOrgAlertRecipient__c == null) {
                user.ScratchOrgAlertRecipient__c = user.Email;
            }

            if (user.ScratchOrgAlertNotificationDays__c == null) {
                user.ScratchOrgAlertNotificationDays__c = DEFAULT_DAYS_BEFORE;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: You don\'t have access to the configuration fields.'));
        }
    }

    public static Boolean validateDaysBefore(Decimal days_before) {
        return Integer.valueOf(days_before) >= 0;
    }

    public PageReference save() {
        if (ScratchOrgAlert.isObjectUpdateable(Schema.SObjectType.User, ScratchOrgAlert.UserQueryFields)) {
            Boolean success = true;

            if (!validateDaysBefore(this.user.ScratchOrgAlertNotificationDays__c)) {
                success = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Days before cannot be negative.'));
            }

            if (success) {
                Update this.user;
                disableSaveUserNotificationSettings();

                List<User> enabledUsers = Database.query('SELECT ' + String.join(ScratchOrgAlert.UserQueryFields, ', ') + ' FROM User WHERE ScratchOrgAlertEnabled__c = true');
                List<CronJobDetail> jobDetails = getJobDetails();

                if (enabledUsers.size() > 0 && (jobDetails == null || jobDetails.size() == 0)) {
                    ScratchOrgAlertScheduler.scheduleAlert();
                } else if (enabledUsers.isEmpty() && (jobDetails != null && jobDetails.size() == 1)) {
                    String cronDetailId = jobDetails[0].Id;
                    if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.CronTrigger, ScratchOrgAlert.CronTriggerFields)) {
                        String cronId = [SELECT Id FROM CronTrigger WHERE CronJobDetailId = :cronDetailId LIMIT 1].Id;
                        System.abortJob(cronId);
                    }
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: You don\'t have access to update the alert settings.'));
        }
        return null;
    }

    public PageReference disableSaveUserNotificationSettings() {
        saveUserNotificationSettingsDisabled = true;
        return null;
    }
    
    public PageReference enableSaveUserNotificationSettings() {
        saveUserNotificationSettingsDisabled = false;
        return null;
    }

    public static List<CronJobDetail> getJobDetails() {
        if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.CronJobDetail, ScratchOrgAlert.CronJobFields)) {
            return [SELECT Id FROM CronJobDetail WHERE Name = :ScratchOrgAlertScheduler.JOB_NAME];
        } else {
            return null;
        }
    }
}