public class ScratchOrgAlertScheduler {

    public static void scheduleAlert() {
        String scheduledTime = '12:00:00'; // TODO: move this to CMT
        List<String> split = scheduledTime.split(':');
        String sch = '0 ' + split.get(1) + ' ' + split.get(0) + ' * * ?';
        system.schedule('Scratch Org Alert Executor', sch, new ScratchOrgAlertExecutor());
    }
}