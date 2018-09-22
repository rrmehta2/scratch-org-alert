public with sharing class ScratchOrgAlertScheduler {

    public static void scheduleAlert(String scheduledTime) {
        List<String> split = scheduledTime.split(':');
        String sch = '0 ' + split.get(1) + ' ' + split.get(0) + ' * * ?';
        system.schedule('Scratch Org Alert Executor', sch, new ScratchOrgAlertExecutor());
    }
}