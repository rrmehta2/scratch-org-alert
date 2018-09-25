public with sharing class ScratchOrgAlertScheduler {

    public final static String SCHEDULED_TIME = '00:00';
    public final static String JOB_NAME = 'Scratch Org Alert Job';

    public static void scheduleAlert() {
        scheduleAlert(getScheduledTime());
    }

    public static void scheduleAlert(String scheduledTime) {
        List<String> split = scheduledTime.split(':');
        String sch = '0 ' + split.get(1) + ' ' + split.get(0) + ' * * ?';
        System.schedule(ScratchOrgAlertScheduler.JOB_NAME, sch, new ScratchOrgAlert());
    }

    public static String getScheduledTime() {
        List<ScratchOrgAlertSchedule__mdt> scheduledTimes = [SELECT ScheduleTime__c FROM ScratchOrgAlertSchedule__mdt WHERE DeveloperName = 'EnabledTime'];
        return (scheduledTimes != null && scheduledTimes.size() == 1) ? scheduledTimes.get(0).ScheduleTime__c : ScratchOrgAlertScheduler.JOB_NAME;
    }
}