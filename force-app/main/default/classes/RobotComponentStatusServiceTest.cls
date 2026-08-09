@IsTest
private class RobotComponentStatusServiceTest {

    @TestSetup
    static void createParentRobot() {
        insert new Robot__c(
            Name = 'Component Test Robot',
            Robot_Serial_Number__c = 'COMPONENT-TEST-ROBOT',
            Robot_Type__c = 'Humanoid',
            Operational_Status__c = 'Operational',
            Health_Score__c = 90
        );
    }

    @IsTest
    static void ignoresComponentWithMissingOperatingHours() {
        Robot_Component__c incompleteComponent =
            new Robot_Component__c(
                Expected_Service_Life_Hours__c = 1000,
                Current_Operating_Hours__c = null,
                Component_Status__c = 'Warning'
            );

        Test.startTest();

        RobotComponentStatusService.applyStatus(
            new List<Robot_Component__c>{
                incompleteComponent
            }
        );

        Test.stopTest();

        System.assertEquals(
            'Warning',
            incompleteComponent.Component_Status__c,
            'The service should preserve the status when hours are missing.'
        );
    }
    @IsTest
    static void assignsStatusesDuringBulkInsert() {
        Id robotId = [
            SELECT Id
            FROM Robot__c
            WHERE Robot_Serial_Number__c = 'COMPONENT-TEST-ROBOT'
            LIMIT 1
        ].Id;

        List<Robot_Component__c> components =
            new List<Robot_Component__c>{
                new Robot_Component__c(
                    Robot__c = robotId,
                    Component_Serial_Number__c = 'STATUS-HEALTHY',
                    Component_Type__c = 'Battery',
                    Expected_Service_Life_Hours__c = 1000,
                    Current_Operating_Hours__c = 200
                ),
                new Robot_Component__c(
                    Robot__c = robotId,
                    Component_Serial_Number__c = 'STATUS-WARNING',
                    Component_Type__c = 'Actuator',
                    Expected_Service_Life_Hours__c = 1000,
                    Current_Operating_Hours__c = 800
                ),
                new Robot_Component__c(
                    Robot__c = robotId,
                    Component_Serial_Number__c = 'STATUS-MAINTENANCE',
                    Component_Type__c = 'Motor',
                    Expected_Service_Life_Hours__c = 1000,
                    Current_Operating_Hours__c = 1000
                ),
                new Robot_Component__c(
                    Robot__c = robotId,
                    Component_Serial_Number__c = 'STATUS-FAILED',
                    Component_Type__c = 'Camera',
                    Expected_Service_Life_Hours__c = 1000,
                    Current_Operating_Hours__c = 100,
                    Component_Status__c = 'Failed'
                ),
                new Robot_Component__c(
                    Robot__c = robotId,
                    Component_Serial_Number__c = 'STATUS-REPLACED',
                    Component_Type__c = 'IMU',
                    Expected_Service_Life_Hours__c = 1000,
                    Current_Operating_Hours__c = 100,
                    Component_Status__c = 'Replaced'
                )
            };

        Test.startTest();
        insert components;
        Test.stopTest();

        Map<String, Robot_Component__c> componentsBySerial =
            new Map<String, Robot_Component__c>();

        for (Robot_Component__c component : [
            SELECT
                Component_Serial_Number__c,
                Component_Status__c
            FROM Robot_Component__c
            WHERE Robot__c = :robotId
        ]) {
            componentsBySerial.put(
                component.Component_Serial_Number__c,
                component
            );
        }

        System.assertEquals(
            'Healthy',
            componentsBySerial.get('STATUS-HEALTHY')
                .Component_Status__c
        );
        System.assertEquals(
            'Warning',
            componentsBySerial.get('STATUS-WARNING')
                .Component_Status__c
        );
        System.assertEquals(
            'Maintenance Required',
            componentsBySerial.get('STATUS-MAINTENANCE')
                .Component_Status__c
        );
        System.assertEquals(
            'Failed',
            componentsBySerial.get('STATUS-FAILED')
                .Component_Status__c
        );
        System.assertEquals(
            'Replaced',
            componentsBySerial.get('STATUS-REPLACED')
                .Component_Status__c
        );
    }

    @IsTest
    static void recalculatesStatusDuringUpdate() {
        Id robotId = [
            SELECT Id
            FROM Robot__c
            WHERE Robot_Serial_Number__c = 'COMPONENT-TEST-ROBOT'
            LIMIT 1
        ].Id;

        Robot_Component__c component = new Robot_Component__c(
            Robot__c = robotId,
            Component_Serial_Number__c = 'STATUS-UPDATE',
            Component_Type__c = 'Compute Module',
            Expected_Service_Life_Hours__c = 1000,
            Current_Operating_Hours__c = 100
        );

        insert component;
        Robot_Component__c componentToUpdate = [
            SELECT
                Id,
                Expected_Service_Life_Hours__c,
                Current_Operating_Hours__c,
                Component_Status__c
            FROM Robot_Component__c
            WHERE Id = :component.Id
        ];

        componentToUpdate.Current_Operating_Hours__c = 850;

        Test.startTest();
        update componentToUpdate;
        Test.stopTest();

        Robot_Component__c updatedComponent = [
            SELECT Component_Status__c
            FROM Robot_Component__c
            WHERE Id = :component.Id
        ];

        System.assertEquals(
            'Warning',
            updatedComponent.Component_Status__c
        );
    }

    @IsTest
    static void safelyHandlesNullInputs() {
        Test.startTest();

        RobotComponentStatusService.applyStatus(null);
        RobotComponentStatusService.applyStatus(
            new List<Robot_Component__c>{ null }
        );

        Test.stopTest();

        System.assert(true, 'Null inputs should not cause an exception.');
    }
}