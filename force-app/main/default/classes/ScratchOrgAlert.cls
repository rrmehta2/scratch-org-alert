public with sharing class ScratchOrgAlert implements Schedulable {

    public static String[] ActiveScratchOrgQueryFields = new String[] {
        'CreatedById', 'CreatedDate',
        'Description', 'Edition', 'ExpirationDate',
        'Id', 'LastLoginDate', 'LastModifiedById',
        'LastModifiedDate', 'LastViewedDate', 'Name',
        'Namespace', 'OrgName', 'OwnerId',
        'ScratchOrg', 'ScratchOrgInfoId', 'SignupEmail',
        'SignupInstance', 'SignupTrialDays', 'SignupUsername',
        'SystemModstamp'
    };

    public static String[] UserQueryFields = new String[] {
        'Id', 'Email', 'ScratchOrgAlertNotificationDays__c',
        'ScratchOrgAlertRecipient__c', 'ScratchOrgAlertEnabled__c'
    };
    
    public static String[] CronJobFields = new String[] {'Name', 'Id'};

    public static String[] CronTriggerFields = new String[] {'CronJobDetailId'};

    public static String[] EmailQueryFields = new String[] {'UserId__c'};

    public static String[] EmailItemQueryFields = new String[] {
        'CreatedById__c', 'CreatedDate__c',
        'Description__c', 'Edition__c',
        'ExpirationDate__c', 'LastLoginDate__c', 'LastModifiedById__c',
        'LastModifiedDate__c', 'LastViewedDate__c', 'Name__c',
        'Namespace__c', 'OrgName__c', 'OwnerId__c',
        'ScratchOrg__c', 'ScratchOrgAlertEmail__c', 'ScratchOrgInfoId__c', 
        'SignupEmail__c', 'SignupInstance__c', 'SignupTrialDays__c', 
        'SystemModstamp__c', 'SignupUsername__c'
    };

    public static String[] EmailTemplateFields = new String[] {'Id', 'Body', 'DeveloperName'};

    public void execute(SchedulableContext cntx) {
        run();
    }

    // Run for all users with active orgs
    public static void run() {
        Map<Id, List<ActiveScratchOrg>> orgs = queryActiveOrgs();
        emailOrgOwners(orgs);
    }

    // Run for specific set of users (used in trigger)
    public static void run(List<User> u) {
        Map<Id, List<ActiveScratchOrg>> orgs = queryActiveOrgs(u);
        emailOrgOwners(orgs);
    }

    // Find all scratch orgs
    public static Map<Id, List<ActiveScratchOrg>> queryActiveOrgs() {
        if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.User, ScratchOrgAlert.UserQueryFields)) {
            return queryActiveOrgs(Database.query('SELECT ' + String.join(ScratchOrgAlert.UserQueryFields, ', ') + ' FROM User WHERE ScratchOrgAlertEnabled__c = true'));
        } else {
            System.debug(LoggingLevel.ERROR, 'You don\'t have access to the user fields required.');
            return new Map<Id, List<ActiveScratchOrg>>();
        }
    }

    // Find all scratch orgs for a specific subset of users
    public static Map<Id, List<ActiveScratchOrg>> queryActiveOrgs(List<User> users) {
        List<Id> userIds = new List<Id>();
        Map<Id, Integer> userNotificationDays = new Map<Id, Integer>();
        Map<Id, List<ActiveScratchOrg>> notifiableOrgs = new Map<Id, List<ActiveScratchOrg>>();

        for (User u : users) {
            if (!u.ScratchOrgAlertEnabled__c) {
                System.debug('Feature disabled. Skipping user.');
                continue;
            }

            if (String.isBlank(u.ScratchOrgAlertRecipient__c)) {
                System.debug('Recipient email not set. Skipping user.');
                continue;
            }

            if (u.ScratchOrgAlertNotificationDays__c == null || u.ScratchOrgAlertNotificationDays__c < 1) {
                System.debug('Alert duration before not set. Skipping user.');
                continue;
            }

            userIds.add(u.Id);
            userNotificationDays.put(u.Id, Integer.valueOf(u.ScratchOrgAlertNotificationDays__c));
        }

        if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.ActiveScratchOrg, ScratchOrgAlert.ActiveScratchOrgQueryFields)) {
            List<ActiveScratchOrg> activeOrgs = Database.query('SELECT ' +
                String.join(ScratchOrgAlert.ActiveScratchOrgQueryFields, ', ') +
                ' FROM ActiveScratchOrg WHERE IsDeleted = false AND OwnerId IN :userIds'
            );

            for (ActiveScratchOrg org : activeOrgs) {
                Integer notificationDays = userNotificationDays.get(org.OwnerId);
                if (businessDaysBetween(System.today(), org.expirationdate) <= notificationDays) {
                    List<ActiveScratchOrg> tmp = (notifiableOrgs.containsKey(org.OwnerId)) ? notifiableOrgs.get(org.OwnerId) : new List<ActiveScratchOrg>();
                    tmp.add(org);
                    notifiableOrgs.put(org.OwnerId, tmp);
                }
            }
        } else {
            System.debug(LoggingLevel.ERROR, 'You don\'t have access to ActiveScratchOrgs.');
        }

        return notifiableOrgs;
    }

    public static Boolean emailOrgOwners(Map<Id, List<ActiveScratchOrg>> notifiableOrgs) {
        if (ScratchOrgAlert.ensureEmailObjectPermissions()
            && ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.User, ScratchOrgAlert.UserQueryFields)
            && ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.ActiveScratchOrg, ScratchOrgAlert.ActiveScratchOrgQueryFields)
        ) {
            Set<Id> userIds = notifiableOrgs.keySet();
            List<User> users = Database.query('SELECT ' + String.join(ScratchOrgAlert.UserQueryFields, ', ') + ' FROM User WHERE Id IN :userIds');

            List<ScratchOrgAlertEmail__c> emails = new List<ScratchOrgAlertEmail__c>();
            Map<Id, String> recipients = new Map<Id, String>();

            for (User u : users) {
                if (String.isBlank(u.ScratchOrgAlertRecipient__c)) {
                    System.debug('Recipient email not set. Skipping user.');
                    continue;
                } else {
                    recipients.put(u.Id, u.ScratchOrgAlertRecipient__c);
                    emails.add(new ScratchOrgAlertEmail__c(UserId__c = u.Id));
                }
            }
            insert emails;

            List<ScratchOrgAlertEmailItem__c> emailItemList = new List<ScratchOrgAlertEmailItem__c>();
            for (ScratchOrgAlertEmail__c email : emails) {
                for(ActiveScratchOrg o : notifiableOrgs.get(email.UserId__c)) {
                    ScratchOrgAlertEmailItem__c emailItem = new ScratchOrgAlertEmailItem__c();

                    emailItem.CreatedById__c = o.CreatedById;
                    emailItem.CreatedDate__c = o.CreatedDate;
                    emailItem.Description__c = o.Description;
                    emailItem.ScratchOrgAlertEmail__c = email.Id;
                    emailItem.Edition__c = o.Edition;
                    emailItem.ExpirationDate__c = o.ExpirationDate;
                    emailItem.LastLoginDate__c = o.LastLoginDate;
                    emailItem.LastModifiedById__c = o.LastModifiedById;
                    emailItem.LastModifiedDate__c = o.LastModifiedDate;
                    emailItem.LastViewedDate__c = o.LastViewedDate;
                    emailItem.Name__c = o.Name;
                    emailItem.Namespace__c = o.Namespace;
                    emailItem.OrgName__c = o.OrgName;
                    emailItem.OwnerId__c = o.OwnerId;
                    emailItem.ScratchOrg__c = o.ScratchOrg;
                    emailItem.ScratchOrgInfoId__c = o.ScratchOrgInfoId;
                    emailItem.SignupEmail__c = o.SignupEmail;
                    emailItem.SignupInstance__c = o.SignupInstance;
                    emailItem.SignupTrialDays__c = o.SignupTrialDays;
                    emailItem.SystemModstamp__c = o.SystemModstamp;
                    emailItem.SignupUsername__c = o.SignupUsername;

                    emailItemList.add(emailItem);
                }
            }
            insert emailItemList;

            return ScratchOrgAlertEmailer.sendEmails(recipients, [SELECT Id, UserId__c FROM ScratchOrgAlertEmail__c]);
        } else {
            System.debug(LoggingLevel.ERROR, 'You don\'t have access to either the email objects, custom user fields, or ActiveScratchOrgs.');
            return false;
        }
    }

    // Standard business days of Monday-Friday
    public static Integer businessDaysBetween(Date d1, Date d2) {
        Integer days = 0;
        Integer[] dayVal = new Integer[] {0,0,1,1,1,1,1};
        Date aSaturday = Date.newInstance(2017, 5, 27);

        for (Date d = d1; d < d2; d+=1) days += dayVal[math.mod(aSaturday.daysBetween(d),7)];
        return days;
    }

    public static Boolean isObjectAccessible(Schema.DescribeSObjectResult describeResult, String[] fields) {
        Map<String,Schema.SObjectField> perms = describeResult.fields.getMap();
        for (String k : fields) {
            if (!perms.get(k).getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }

    public static Boolean ensureEmailObjectPermissions() {
        Map<String,Schema.SObjectField> emailPermissions = Schema.SObjectType.ScratchOrgAlertEmail__c.fields.getMap();
        for (String k : ScratchOrgAlert.EmailQueryFields) {
            if (!(emailPermissions.get(k).getDescribe().isAccessible() && emailPermissions.get(k).getDescribe().isCreateable())) {
                return false;
            }
        }

        Map<String,Schema.SObjectField> emailItemPermissions = Schema.SObjectType.ScratchOrgAlertEmailItem__c.fields.getMap();
        for (String k : ScratchOrgAlert.EmailItemQueryFields) {
            if (!(emailItemPermissions.get(k).getDescribe().isAccessible() && emailItemPermissions.get(k).getDescribe().isCreateable())) {
                return false;
            }
        }

        return true;
    }

    public static Boolean isObjectUpdateable(Schema.DescribeSObjectResult describeResult, String[] fields) {
        Map<String,Schema.SObjectField> perms = describeResult.fields.getMap();
        for (String k : fields) {
            if (!k.equals('Id') && !perms.get(k).getDescribe().isUpdateable()) {
                return false;
            }
        }

        return true;
    }
}