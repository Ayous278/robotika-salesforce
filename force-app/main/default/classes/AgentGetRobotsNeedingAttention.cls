public with sharing class AgentGetRobotsNeedingAttention {

    public class Request {
        @InvocableVariable(
            label='Maximum Health Score'
            description='Return robots at or below this health score. Defaults to 80.'
        )
        public Integer maximumHealthScore;
    }

    public class Response {
        @InvocableVariable(
            label='Robot Count'
            description='Number of robots requiring attention.'
        )
        public Integer robotCount;

        @InvocableVariable(
            label='Robot Summary'
            description='Grounded summary of robots requiring attention.'
        )
        public String robotSummary;
    }

    @InvocableMethod(
        label='Get Robots Needing Attention'
        description='Returns Robotika robots with low health or a degraded, maintenance-required, or unavailable status.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request requestValue : requests) {
            Integer threshold =
                requestValue == null || requestValue.maximumHealthScore == null
                ? 80
                : requestValue.maximumHealthScore;

            List<Robot__c> robots =
                RobotHealthService.getRobotsNeedingAttention(threshold);

            Response responseValue = new Response();
            responseValue.robotCount = robots.size();

            if (robots.isEmpty()) {
                responseValue.robotSummary =
                    'No robots currently require attention for a maximum health score of ' +
                    threshold + '.';
            } else {
                List<String> robotLines = new List<String>();

                for (Robot__c robot : robots) {
                    robotLines.add(
                        'Name: ' + robot.Name +
                        '; Serial: ' + robot.Robot_Serial_Number__c +
                        '; Status: ' + robot.Operational_Status__c +
                        '; Health Score: ' + robot.Health_Score__c +
                        '; Components: ' + robot.Total_Components__c
                    );
                }

                responseValue.robotSummary = String.join(robotLines, '\n');
            }

            responses.add(responseValue);
        }

        return responses;
    }
}
