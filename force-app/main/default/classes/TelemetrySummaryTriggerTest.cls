@IsTest
private class TelemetrySummaryTriggerTest {

    @IsTest
    static void processesBulkTelemetryInsert() {
        Robot__c criticalRobot =
            RobotikaTestDataFactory.createRobot(true);

        Robot__c offlineRobot =
            RobotikaTestDataFactory.createRobot(true);

        Telemetry_Summary__c criticalTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                criticalRobot.Id,
                'Critical',
                false
            );

        Telemetry_Summary__c offlineTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                offlineRobot.Id,
                'Offline',
                false
            );

        Test.startTest();

        insert new List<Telemetry_Summary__c>{
            criticalTelemetry,
            offlineTelemetry
        };

        Test.stopTest();

        Map<Id, Robot__c> updatedRobots =
            new Map<Id, Robot__c>([
                SELECT Id, Health_Score__c
                FROM Robot__c
                WHERE Id IN :new Set<Id>{
                    criticalRobot.Id,
                    offlineRobot.Id
                }
            ]);

        System.assertEquals(
            40,
            updatedRobots.get(criticalRobot.Id).Health_Score__c,
            'Critical telemetry should set health to 40.'
        );

        System.assertEquals(
            10,
            updatedRobots.get(offlineRobot.Id).Health_Score__c,
            'Offline telemetry should set health to 10.'
        );
    }
}