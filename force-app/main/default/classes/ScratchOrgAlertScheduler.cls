public with sharing class ScratchOrgAlertScheduler {

    public final static String SCHEDULED_TIME = '00:00';

    public static void scheduleAlert() {
        scheduleAlert(SCHEDULED_TIME);
    }

    public static void scheduleAlert(String scheduledTime) {
        List<String> split = scheduledTime.split(':');
        String sch = '0 ' + split.get(1) + ' ' + split.get(0) + ' * * ?';
        System.schedule('Scratch Org Alert', sch, new ScratchOrgAlert());
    }
}