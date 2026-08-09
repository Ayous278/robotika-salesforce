@IsTest
private class RobotIngestionServiceTest {

    @IsTest
    static void insertsNewRobot() {
        Robot__c newRobot = new Robot__c(
            Name = 'Ingestion Test Robot',
            Robot_Serial_Number__c = 'INGEST-001',
            Robot_Type__c = 'Humanoid',
            Operational_Status__c = 'Operational',
            Health_Score__c = 90
        );

        Test.startTest();

        Database.UpsertResult[] results =
            RobotIngestionService.upsertRobots(
                new List<Robot__c>{ newRobot }
            );

        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess());
        System.assert(results[0].isCreated());

        Robot__c insertedRobot = [
            SELECT
                Name,
                Robot_Serial_Number__c,
                Operational_Status__c,
                Health_Score__c
            FROM Robot__c
            WHERE Robot_Serial_Number__c = 'INGEST-001'
            LIMIT 1
        ];

        System.assertEquals('Ingestion Test Robot', insertedRobot.Name);
        System.assertEquals('Operational', insertedRobot.Operational_Status__c);
        System.assertEquals(90, insertedRobot.Health_Score__c);
    }

    @IsTest
    static void updatesExistingRobot() {
        insert new Robot__c(
            Name = 'Existing Robot',
            Robot_Serial_Number__c = 'INGEST-002',
            Robot_Type__c = 'Quadruped',
            Operational_Status__c = 'Operational',
            Health_Score__c = 95
        );

        Robot__c incomingRobot = new Robot__c(
            Name = 'Updated Robot',
            Robot_Serial_Number__c = 'INGEST-002',
            Robot_Type__c = 'Quadruped',
            Operational_Status__c = 'Degraded',
            Health_Score__c = 65
        );

        Test.startTest();

        Database.UpsertResult[] results =
            RobotIngestionService.upsertRobots(
                new List<Robot__c>{ incomingRobot }
            );

        Test.stopTest();

        System.assert(results[0].isSuccess());
        System.assert(!results[0].isCreated());

        Robot__c updatedRobot = [
            SELECT
                Name,
                Operational_Status__c,
                Health_Score__c
            FROM Robot__c
            WHERE Robot_Serial_Number__c = 'INGEST-002'
            LIMIT 1
        ];

        System.assertEquals('Updated Robot', updatedRobot.Name);
        System.assertEquals('Degraded', updatedRobot.Operational_Status__c);
        System.assertEquals(65, updatedRobot.Health_Score__c);
    }

    @IsTest
    static void allowsPartialSuccess() {
        List<Robot__c> robots = new List<Robot__c>{
            new Robot__c(
                Name = 'Valid Robot',
                Robot_Serial_Number__c = 'INGEST-VALID',
                Robot_Type__c = 'Humanoid',
                Operational_Status__c = 'Operational',
                Health_Score__c = 80
            ),
            new Robot__c(
                Name = 'Invalid Robot',
                Robot_Serial_Number__c = 'INGEST-INVALID',
                Robot_Type__c = 'Humanoid',
                Operational_Status__c = 'Operational',
                Health_Score__c = 150
            )
        };

        Test.startTest();

        Database.UpsertResult[] results =
            RobotIngestionService.upsertRobots(robots);

        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assert(results[0].isSuccess());
        System.assert(!results[1].isSuccess());
        System.assert(results[1].getErrors().size() > 0);

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Robot__c
                WHERE Robot_Serial_Number__c IN (
                    'INGEST-VALID',
                    'INGEST-INVALID'
                )
            ]
        );
    }

    @IsTest
    static void rejectsEmptyInput() {
        Boolean exceptionThrown = false;

        try {
            RobotIngestionService.upsertRobots(
                new List<Robot__c>()
            );
        } catch (IllegalArgumentException exceptionValue) {
            exceptionThrown = true;
            System.assertEquals(
                'At least one robot is required.',
                exceptionValue.getMessage()
            );
        }

        System.assert(exceptionThrown);
    }

    @IsTest
    static void rejectsNullRobot() {
        Boolean exceptionThrown = false;

        try {
            RobotIngestionService.upsertRobots(
                new List<Robot__c>{ null }
            );
        } catch (IllegalArgumentException exceptionValue) {
            exceptionThrown = true;
            System.assertEquals(
                'Robot records cannot be null.',
                exceptionValue.getMessage()
            );
        }

        System.assert(exceptionThrown);
    }

    @IsTest
    static void rejectsMissingSerialNumber() {
        Boolean exceptionThrown = false;

        try {
            RobotIngestionService.upsertRobots(
                new List<Robot__c>{
                    new Robot__c(Name = 'Missing Serial')
                }
            );
        } catch (IllegalArgumentException exceptionValue) {
            exceptionThrown = true;
            System.assertEquals(
                'Every robot requires a serial number.',
                exceptionValue.getMessage()
            );
        }

        System.assert(exceptionThrown);
    }

    @IsTest
    static void rejectsDuplicateSerialNumbers() {
        Boolean exceptionThrown = false;

        List<Robot__c> robots = new List<Robot__c>{
            new Robot__c(
                Name = 'First Robot',
                Robot_Serial_Number__c = 'DUPLICATE-001'
            ),
            new Robot__c(
                Name = 'Second Robot',
                Robot_Serial_Number__c = ' duplicate-001 '
            )
        };

        try {
            RobotIngestionService.upsertRobots(robots);
        } catch (IllegalArgumentException exceptionValue) {
            exceptionThrown = true;
            System.assert(
                exceptionValue.getMessage().startsWith(
                    'Duplicate serial number in request:'
                )
            );
        }

        System.assert(exceptionThrown);
    }
}