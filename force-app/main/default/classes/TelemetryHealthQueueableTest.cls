@IsTest
private class TelemetryHealthQueueableTest {

    @IsTest
    static void appliesCriticalHealthScore() {
        Robot__c robot =
            RobotikaTestDataFactory.createRobot(true);

        Telemetry_Summary__c telemetry =
            RobotikaTestDataFactory.createTelemetry(
                robot.Id,
                'Critical',
                true
            );

        Test.startTest();

        Id jobId = System.enqueueJob(
            new TelemetryHealthQueueable(
                new Set<Id>{ telemetry.Id }
            )
        );

        Test.stopTest();

        Robot__c updatedRobot = [
            SELECT Health_Score__c
            FROM Robot__c
            WHERE Id = :robot.Id
        ];

        System.assertEquals(
            40,
            updatedRobot.Health_Score__c,
            'Critical telemetry should set the score to 40.'
        );

        AsyncApexJob completedJob = [
            SELECT Status, JobType
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals('Completed', completedJob.Status);
        System.assertEquals('Queueable', completedJob.JobType);
    }

    @IsTest
    static void appliesLowestScoreForMultipleTelemetryRecords() {
        Robot__c robot =
            RobotikaTestDataFactory.createRobot(true);

        Telemetry_Summary__c warningTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                robot.Id,
                'Warning',
                true
            );

        Telemetry_Summary__c offlineTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                robot.Id,
                'Offline',
                true
            );

        Test.startTest();

        System.enqueueJob(
            new TelemetryHealthQueueable(
                new Set<Id>{
                    warningTelemetry.Id,
                    offlineTelemetry.Id
                }
            )
        );

        Test.stopTest();

        Robot__c updatedRobot = [
            SELECT Health_Score__c
            FROM Robot__c
            WHERE Id = :robot.Id
        ];

        System.assertEquals(
            10,
            updatedRobot.Health_Score__c,
            'The lowest telemetry score should win.'
        );
    }

    @IsTest
    static void appliesNormalHealthScore() {
        Telemetry_Summary__c telemetry =
            new Telemetry_Summary__c(
                Telemetry_Status__c = 'Normal',
                Battery_Level__c = 95,
                CPU_Utilization__c = 25,
                CPU_Temperature_Celsius__c = 40,
                Average_Motor_Temperature_Celsius__c = 40,
                Network_Latency_Milliseconds__c = 10,
                Active_Fault_Count__c = 0
            );

        Test.startTest();

        Decimal calculatedScore =
            TelemetryHealthQueueable.calculateTelemetryScore(telemetry);

        Test.stopTest();

        System.assertEquals(
            95,
            calculatedScore,
            'Normal telemetry should produce a score of 95.'
        );
    }
    @IsTest
    static void safelyHandlesEmptyInput() {
        Test.startTest();

        Id jobId = System.enqueueJob(
            new TelemetryHealthQueueable(new Set<Id>())
        );

        Test.stopTest();

        AsyncApexJob completedJob = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals(
            'Completed',
            completedJob.Status,
            'An empty job should finish without an error.'
        );
    }

    @IsTest
    static void safelyHandlesNullInput() {
        Test.startTest();

        Id jobId = System.enqueueJob(
            new TelemetryHealthQueueable(null)
        );

        Test.stopTest();

        AsyncApexJob completedJob = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertEquals('Completed', completedJob.Status);
    }
}