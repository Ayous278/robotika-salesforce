@IsTest
private class RobotHealthServiceTest {

    @TestSetup
    static void createTestRobots() {
        List<Robot__c> robots = new List<Robot__c>{
            new Robot__c(
                Name = 'Healthy Test Robot',
                Robot_Serial_Number__c = 'TEST-HEALTHY-001',
                Robot_Type__c = 'Humanoid',
                Operational_Status__c = 'Operational',
                Health_Score__c = 92
            ),
            new Robot__c(
                Name = 'Degraded Test Robot',
                Robot_Serial_Number__c = 'TEST-DEGRADED-001',
                Robot_Type__c = 'Quadruped',
                Operational_Status__c = 'Degraded',
                Health_Score__c = 70
            ),
            new Robot__c(
                Name = 'Unavailable Test Robot',
                Robot_Serial_Number__c = 'TEST-UNAVAILABLE-001',
                Robot_Type__c = 'Mobile Manipulator',
                Operational_Status__c = 'Unavailable',
                Health_Score__c = 40
            )
        };

        insert robots;
    }

    @IsTest
    static void returnsRobotsNeedingAttention() {
        Test.startTest();

        List<Robot__c> results =
            RobotHealthService.getRobotsNeedingAttention(75);

        Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'Two robots should require attention.'
        );

        Set<String> returnedSerialNumbers = new Set<String>();

        for (Robot__c robot : results) {
            returnedSerialNumbers.add(robot.Robot_Serial_Number__c);
        }

        System.assert(
            returnedSerialNumbers.contains('TEST-DEGRADED-001'),
            'The degraded robot should be returned.'
        );

        System.assert(
            returnedSerialNumbers.contains('TEST-UNAVAILABLE-001'),
            'The unavailable robot should be returned.'
        );

        System.assert(
            !returnedSerialNumbers.contains('TEST-HEALTHY-001'),
            'The healthy robot should not be returned.'
        );
    }

    @IsTest
    static void rejectsInvalidHealthThreshold() {
        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            RobotHealthService.getRobotsNeedingAttention(101);
        } catch (IllegalArgumentException exceptionValue) {
            exceptionThrown = true;

            System.assertEquals(
                'Maximum health score must be between 0 and 100.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();

        System.assert(
            exceptionThrown,
            'An invalid threshold should throw an exception.'
        );
    }
}