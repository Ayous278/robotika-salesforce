@IsTest
private class AgentGetRobotDetailsTest {

    @IsTest
    static void returnsConsolidatedDetailsBySerialNumber() {
        Robot__c robot = RobotikaTestDataFactory.createRobot(true);
        Robot_Component__c component =
            RobotikaTestDataFactory.createComponent(robot.Id, 850, true);
        RobotikaTestDataFactory.createTelemetry(robot.Id, 'Warning', true);
        RobotikaTestDataFactory.createFault(
            robot.Id,
            component.Id,
            'Medium',
            true
        );

        Mission__c mission = new Mission__c(
            Robot__c = robot.Id,
            External_Mission_ID__c = 'AGENT-DETAIL-MISSION',
            Mission_Type__c = 'Inspection',
            Mission_Status__c = 'In Progress',
            Start_Time__c = System.now()
        );
        insert mission;

        RobotikaTestDataFactory.createWorkOrder(
            robot.Id,
            null,
            component.Id,
            true
        );

        AgentGetRobotDetails.Request requestValue =
            new AgentGetRobotDetails.Request();
        requestValue.nameOrSerial = robot.Robot_Serial_Number__c;

        Test.startTest();
        List<AgentGetRobotDetails.Response> responses =
            AgentGetRobotDetails.execute(
                new List<AgentGetRobotDetails.Request>{ requestValue }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].robotFound);
        System.assertEquals(String.valueOf(robot.Id), responses[0].robotId);
        System.assert(responses[0].robotDetails.contains(robot.Name));
        System.assert(responses[0].robotDetails.contains('Latest Telemetry'));
        System.assert(responses[0].robotDetails.contains('Components:'));
        System.assert(responses[0].robotDetails.contains('Open Faults:'));
        System.assert(responses[0].robotDetails.contains('Recent Missions:'));
        System.assert(
            responses[0].robotDetails.contains('Open Maintenance Work Orders:')
        );
    }

    @IsTest
    static void findsRobotByExactName() {
        Robot__c robot = RobotikaTestDataFactory.createRobot(true);

        AgentGetRobotDetails.Request requestValue =
            new AgentGetRobotDetails.Request();
        requestValue.nameOrSerial = robot.Name;

        List<AgentGetRobotDetails.Response> responses =
            AgentGetRobotDetails.execute(
                new List<AgentGetRobotDetails.Request>{ requestValue }
            );

        System.assertEquals(true, responses[0].robotFound);
        System.assertEquals(String.valueOf(robot.Id), responses[0].robotId);
        System.assert(responses[0].robotDetails.contains('Latest Telemetry: unavailable.'));
    }

    @IsTest
    static void returnsGroundedNoMatchResponse() {
        AgentGetRobotDetails.Request requestValue =
            new AgentGetRobotDetails.Request();
        requestValue.nameOrSerial = 'ROBOT-DOES-NOT-EXIST';

        List<AgentGetRobotDetails.Response> responses =
            AgentGetRobotDetails.execute(
                new List<AgentGetRobotDetails.Request>{ requestValue }
            );

        System.assertEquals(false, responses[0].robotFound);
        System.assertEquals(null, responses[0].robotId);
        System.assert(responses[0].robotDetails.contains('No Robotika robot was found'));
    }

    @IsTest
    static void safelyHandlesBlankAndNullRequests() {
        AgentGetRobotDetails.Request blankRequest =
            new AgentGetRobotDetails.Request();
        blankRequest.nameOrSerial = '   ';

        List<AgentGetRobotDetails.Response> responses =
            AgentGetRobotDetails.execute(
                new List<AgentGetRobotDetails.Request>{ blankRequest, null }
            );

        System.assertEquals(2, responses.size());
        System.assertEquals(false, responses[0].robotFound);
        System.assertEquals(false, responses[1].robotFound);
        System.assert(responses[0].robotDetails.contains('Provide an exact robot name'));
        System.assertEquals(
            0,
            AgentGetRobotDetails.execute(null).size()
        );
    }
}
