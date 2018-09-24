public with sharing class ScratchOrgAlertEmailer {
    private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
        Boolean sendResult = true;
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully');
            } else {
                sendResult = false;
                System.debug('The following errors occurred: ' + res.getErrors());
            }
        }
        return sendResult;
    }

    public static void purgeEmailObjects() {
        if (ScratchOrgAlertEmail__c.SObjectType.getDescribe().isDeletable())
            delete [SELECT Id FROM ScratchOrgAlertEmail__c];
        else
            System.debug(LoggingLevel.ERROR, 'You don\'t have permission to delete ScratchOrgAlertEmail__c; that\'s a problem.');

        // Just in case there are email items that weren't deleted along with their parents
        if (ScratchOrgAlertEmailItem__c.SObjectType.getDescribe().isDeletable())
            delete [SELECT Id FROM ScratchOrgAlertEmailItem__c];
        else
            System.debug(LoggingLevel.ERROR, 'You don\'t have permission to delete ScratchOrgAlertEmailItem__c; that\'s a problem.');
    }

    public static Boolean sendEmails(Map<Id, String> recipients, List<ScratchOrgAlertEmail__c> alertEmails) {
        if (ScratchOrgAlert.isObjectAccessible(Schema.SObjectType.EmailTemplate, ScratchOrgAlert.EmailTemplateFields)) {
            List<EmailTemplate> templates = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'ScratchOrgAlert'];

            if (templates.size() == 0) {
                System.debug(LoggingLevel.ERROR, 'No templates returned by template query; you may not have permission to access the template.');
            } else if (templates.size() == 1) {
                EmailTemplate template = templates[0];

                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for (ScratchOrgAlertEmail__c email : alertEmails) {
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

                    message.setToAddresses(new String[] {recipients.get(email.UserId__c)});
                    message.setTargetObjectId(email.UserId__c);
                    message.setTemplateId(template.Id);
                    message.setWhatId(email.Id);
                    message.saveAsActivity = false;

                    messages.add(message);
                }

                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                purgeEmailObjects();
                return inspectResults(results);
            } else {
                System.debug(LoggingLevel.ERROR, 'Multiple templates returned by template query.');
            }
        }
        return false;
    }
}