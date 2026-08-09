@IsTest
private class RobotTelemetryServiceTest {

    @IsTest
    static void returnsRecentTelemetryInCorrectOrder() {
        Robot__c robot =
            RobotikaTestDataFactory.createRobot(true);

        Telemetry_Summary__c olderTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                robot.Id,
                'Normal',
                false
            );

        olderTelemetry.Recorded_At__c =
            System.now().addHours(-2);

        Telemetry_Summary__c recentTelemetry =
            RobotikaTestDataFactory.createTelemetry(
                robot.Id,
                'Warning',
                false
            );

        recentTelemetry.Recorded_At__c =
            System.now().addMinutes(-10);

        insert new List<Telemetry_Summary__c>{
            olderTelemetry,
            recentTelemetry
        };

        Test.startTest();

        List<Telemetry_Summary__c> results =
            RobotTelemetryService.getRecentTelemetry(
                robot.Id,
                10
            );

        Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'Both telemetry records should be returned.'
        );

        System.assertEquals(
            recentTelemetry.Id,
            results[0].Id,
            'The most recent telemetry must appear first.'
        );

        System.assertEquals(
            olderTelemetry.Id,
            results[1].Id,
            'The older telemetry must appear second.'
        );

        System.assertEquals(
            true,
            results[0].Requires_Attention__c,
            'Warning telemetry should require attention.'
        );
    }

    @IsTest
    static void respectsRequestedRecordLimit() {
        Robot__c robot =
            RobotikaTestDataFactory.createRobot(true);

        List<Telemetry_Summary__c> telemetryRecords =
            new List<Telemetry_Summary__c>();

        for (Integer indexValue = 0;
            indexValue < 3;
            indexValue++) {

            Telemetry_Summary__c telemetry =
                RobotikaTestDataFactory.createTelemetry(
                    robot.Id,
                    'Normal',
                    false
                );

            telemetry.Recorded_At__c =
                System.now().addMinutes(
                    indexValue * -10
                );

            telemetryRecords.add(telemetry);
        }

        insert telemetryRecords;

        Test.startTest();

        List<Telemetry_Summary__c> results =
            RobotTelemetryService.getRecentTelemetry(
                robot.Id,
                2
            );

        Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'The method must respect the requested limit.'
        );
    }

    @IsTest
    static void rejectsMissingRobotId() {
        Test.startTest();

        try {
            RobotTelemetryService.getRecentTelemetry(
                null,
                10
            );

            System.assert(
                false,
                'A missing Robot ID should throw an exception.'
            );
        } catch (IllegalArgumentException exceptionValue) {
            System.assertEquals(
                'A Robot record ID is required.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void rejectsInvalidRecordLimit() {
        Robot__c robot =
            RobotikaTestDataFactory.createRobot(true);

        Test.startTest();

        try {
            RobotTelemetryService.getRecentTelemetry(
                robot.Id,
                0
            );

            System.assert(
                false,
                'An invalid limit should throw an exception.'
            );
        } catch (IllegalArgumentException exceptionValue) {
            System.assertEquals(
                'Record limit must be between 1 and 50.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();
    }
}