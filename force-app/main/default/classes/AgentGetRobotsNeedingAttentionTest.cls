@IsTest
private class AgentGetRobotsNeedingAttentionTest {

    @TestSetup
    static void createRobots() {
        insert new List<Robot__c>{
            new Robot__c(
                Name = 'Agent Healthy Robot',
                Robot_Serial_Number__c = 'AGENT-HEALTHY-001',
                Robot_Type__c = 'Humanoid',
                Operational_Status__c = 'Operational',
                Health_Score__c = 95
            ),
            new Robot__c(
                Name = 'Agent Degraded Robot',
                Robot_Serial_Number__c = 'AGENT-DEGRADED-001',
                Robot_Type__c = 'Quadruped',
                Operational_Status__c = 'Degraded',
                Health_Score__c = 70
            )
        };
    }

    @IsTest
    static void returnsGroundedRobotSummary() {
        AgentGetRobotsNeedingAttention.Request requestValue =
            new AgentGetRobotsNeedingAttention.Request();
        requestValue.maximumHealthScore = 80;

        Test.startTest();
        List<AgentGetRobotsNeedingAttention.Response> responses =
            AgentGetRobotsNeedingAttention.execute(
                new List<AgentGetRobotsNeedingAttention.Request>{ requestValue }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(1, responses[0].robotCount);
        System.assert(responses[0].robotSummary.contains('Agent Degraded Robot'));
        System.assert(responses[0].robotSummary.contains('AGENT-DEGRADED-001'));
        System.assert(!responses[0].robotSummary.contains('Agent Healthy Robot'));
    }

    @IsTest
    static void defaultsThresholdAndHandlesEmptyRequests() {
        Test.startTest();
        List<AgentGetRobotsNeedingAttention.Response> defaultResponses =
            AgentGetRobotsNeedingAttention.execute(
                new List<AgentGetRobotsNeedingAttention.Request>{ null }
            );
        List<AgentGetRobotsNeedingAttention.Response> emptyResponses =
            AgentGetRobotsNeedingAttention.execute(
                new List<AgentGetRobotsNeedingAttention.Request>()
            );
        Test.stopTest();

        System.assertEquals(1, defaultResponses.size());
        System.assertEquals(1, defaultResponses[0].robotCount);
        System.assertEquals(0, emptyResponses.size());
    }
}
