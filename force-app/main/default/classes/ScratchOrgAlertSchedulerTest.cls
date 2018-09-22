@isTest
public with sharing class ScratchOrgAlertSchedulerTest {
    
    @isTest
    public static void testScheduler() {
        ScratchOrgAlertScheduler.scheduleAlert('12:00');
        List<AsyncApexJob> aj = [SELECT id FROM AsyncApexJob];
        System.assert(aj.size() == 1);
    }

    @isTest
    public static void testIgnoreMultipleSchedulers() {
        ScratchOrgAlertScheduler.scheduleAlert('12:00');
        List<AsyncApexJob> aj = [SELECT id FROM AsyncApexJob];
        System.assert(aj.size() == 1);
        try {
            ScratchOrgAlertScheduler.scheduleAlert('12:01');
        } catch (AsyncException e) {
            System.assert(true);
            return;
        }
        System.assert(false, 'No exception thrown.');
    }
}
