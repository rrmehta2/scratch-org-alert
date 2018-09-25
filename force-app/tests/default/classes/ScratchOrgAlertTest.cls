@isTest
public with sharing class ScratchOrgAlertTest {
    
    @isTest
    public static void testBusinessDaysBetween() {
        // Weekend and following monday
        System.assertEquals(1, ScratchOrgAlert.businessDaysBetween(Date.newInstance(2017, 6, 2), Date.newInstance(2017, 6, 4)));
        System.assertEquals(1, ScratchOrgAlert.businessDaysBetween(Date.newInstance(2017, 6, 2), Date.newInstance(2017, 6, 5)));

        // Tuesday following weekend
        System.assertEquals(2, ScratchOrgAlert.businessDaysBetween(Date.newInstance(2017, 6, 2), Date.newInstance(2017, 6, 6)));

        // Days within business week
        System.assertEquals(3, ScratchOrgAlert.businessDaysBetween(Date.newInstance(2017, 6, 5), Date.newInstance(2017, 6, 8)));
    }
}