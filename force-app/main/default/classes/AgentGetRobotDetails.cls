public with sharing class AgentGetRobotDetails {

    public class Request {
        @InvocableVariable(
            label='Robot Name or Serial Number'
            description='Exact Robot name or unique Robot serial number.'
            required=true
        )
        public String nameOrSerial;
    }

    public class Response {
        @InvocableVariable(label='Robot Found')
        public Boolean robotFound;

        @InvocableVariable(label='Robot ID')
        public String robotId;

        @InvocableVariable(
            label='Robot Details'
            description='Grounded operational details retrieved from Salesforce.'
        )
        public String robotDetails;
    }

    @InvocableMethod(
        label='Get Robot Details'
        description='Finds a Robotika robot by exact name or serial number and returns its current operational details.'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null) {
            return responses;
        }

        for (Request requestValue : requests) {
            responses.add(getDetails(requestValue));
        }

        return responses;
    }

    private static Response getDetails(Request requestValue) {
        Response responseValue = new Response();
        responseValue.robotFound = false;

        String identifier = requestValue == null
            ? null
            : requestValue.nameOrSerial;

        if (String.isBlank(identifier)) {
            responseValue.robotDetails =
                'Provide an exact robot name or serial number.';
            return responseValue;
        }

        identifier = identifier.trim();

        List<Robot__c> robots = [
            SELECT
                Id,
                Name,
                Robot_Serial_Number__c,
                Robot_Type__c,
                Robot_Model__c,
                Operational_Status__c,
                Health_Score__c,
                Total_Components__c,
                Total_Operating_Hours__c,
                Last_Service_Date__c,
                Next_Service_Date__c
            FROM Robot__c
            WHERE Robot_Serial_Number__c = :identifier
            WITH USER_MODE
            LIMIT 1
        ];

        if (robots.isEmpty()) {
            robots = [
                SELECT
                    Id,
                    Name,
                    Robot_Serial_Number__c,
                    Robot_Type__c,
                    Robot_Model__c,
                    Operational_Status__c,
                    Health_Score__c,
                    Total_Components__c,
                    Total_Operating_Hours__c,
                    Last_Service_Date__c,
                    Next_Service_Date__c
                FROM Robot__c
                WHERE Name = :identifier
                WITH USER_MODE
                ORDER BY CreatedDate ASC
                LIMIT 2
            ];
        }

        if (robots.isEmpty()) {
            responseValue.robotDetails =
                'No Robotika robot was found with the exact name or serial number "' +
                identifier + '".';
            return responseValue;
        }

        if (robots.size() > 1) {
            responseValue.robotDetails =
                'More than one robot has the name "' + identifier +
                '". Ask the user for its serial number.';
            return responseValue;
        }

        Robot__c robot = robots[0];
        responseValue.robotFound = true;
        responseValue.robotId = String.valueOf(robot.Id);
        responseValue.robotDetails = buildSummary(robot);
        return responseValue;
    }

    private static String buildSummary(Robot__c robot) {
        List<String> sections = new List<String>();

        sections.add(
            'Robot: ' + robot.Name +
            '; Serial: ' + valueOrUnavailable(robot.Robot_Serial_Number__c) +
            '; Type: ' + valueOrUnavailable(robot.Robot_Type__c) +
            '; Model: ' + valueOrUnavailable(robot.Robot_Model__c) +
            '; Status: ' + valueOrUnavailable(robot.Operational_Status__c) +
            '; Health Score: ' + valueOrUnavailable(robot.Health_Score__c) +
            '; Components: ' + valueOrUnavailable(robot.Total_Components__c) +
            '; Operating Hours: ' + valueOrUnavailable(robot.Total_Operating_Hours__c) +
            '; Last Service: ' + valueOrUnavailable(robot.Last_Service_Date__c) +
            '; Next Service: ' + valueOrUnavailable(robot.Next_Service_Date__c)
        );

        List<Telemetry_Summary__c> telemetryRecords = [
            SELECT
                Recorded_At__c,
                Telemetry_Status__c,
                Battery_Level__c,
                CPU_Utilization__c,
                CPU_Temperature_Celsius__c,
                Average_Motor_Temperature_Celsius__c,
                Network_Latency_Milliseconds__c,
                Active_Fault_Count__c,
                Requires_Attention__c
            FROM Telemetry_Summary__c
            WHERE Robot__c = :robot.Id
            WITH USER_MODE
            ORDER BY Recorded_At__c DESC
            LIMIT 1
        ];

        if (telemetryRecords.isEmpty()) {
            sections.add('Latest Telemetry: unavailable.');
        } else {
            Telemetry_Summary__c telemetry = telemetryRecords[0];
            sections.add(
                'Latest Telemetry: Recorded ' + valueOrUnavailable(telemetry.Recorded_At__c) +
                '; Status: ' + valueOrUnavailable(telemetry.Telemetry_Status__c) +
                '; Battery: ' + valueOrUnavailable(telemetry.Battery_Level__c) + '%' +
                '; CPU: ' + valueOrUnavailable(telemetry.CPU_Utilization__c) + '%' +
                '; CPU Temperature: ' + valueOrUnavailable(telemetry.CPU_Temperature_Celsius__c) + ' C' +
                '; Motor Temperature: ' + valueOrUnavailable(telemetry.Average_Motor_Temperature_Celsius__c) + ' C' +
                '; Network Latency: ' + valueOrUnavailable(telemetry.Network_Latency_Milliseconds__c) + ' ms' +
                '; Active Faults: ' + valueOrUnavailable(telemetry.Active_Fault_Count__c) +
                '; Requires Attention: ' + telemetry.Requires_Attention__c
            );
        }

        List<Robot_Component__c> components = [
            SELECT
                Name,
                Component_Type__c,
                Component_Serial_Number__c,
                Component_Status__c,
                Service_Life_Remaining__c
            FROM Robot_Component__c
            WHERE Robot__c = :robot.Id
            WITH USER_MODE
            ORDER BY Component_Status__c, Name
            LIMIT 10
        ];
        sections.add(summarizeComponents(components));

        List<Robot_Fault__c> faults = [
            SELECT
                Name,
                Fault_Code__c,
                Severity__c,
                Fault_Status__c,
                Detected_At__c
            FROM Robot_Fault__c
            WHERE
                Robot__c = :robot.Id
                AND Fault_Status__c IN ('Open', 'Investigating')
            WITH USER_MODE
            ORDER BY Detected_At__c DESC
            LIMIT 10
        ];
        sections.add(summarizeFaults(faults));

        List<Mission__c> missions = [
            SELECT
                Name,
                External_Mission_ID__c,
                Mission_Type__c,
                Mission_Status__c,
                Start_Time__c,
                End_Time__c
            FROM Mission__c
            WHERE Robot__c = :robot.Id
            WITH USER_MODE
            ORDER BY Start_Time__c DESC NULLS LAST
            LIMIT 5
        ];
        sections.add(summarizeMissions(missions));

        List<Maintenance_Work_Order__c> workOrders = [
            SELECT
                Name,
                Work_Order_Status__c,
                Priority__c,
                Maintenance_Type__c,
                Scheduled_Start__c,
                Scheduled_End__c
            FROM Maintenance_Work_Order__c
            WHERE
                Robot__c = :robot.Id
                AND Work_Order_Status__c NOT IN ('Completed', 'Cancelled')
            WITH USER_MODE
            ORDER BY Scheduled_Start__c ASC NULLS LAST
            LIMIT 5
        ];
        sections.add(summarizeWorkOrders(workOrders));

        return String.join(sections, '\n');
    }

    private static String summarizeComponents(List<Robot_Component__c> records) {
        if (records.isEmpty()) {
            return 'Components: none found.';
        }

        List<String> values = new List<String>();
        for (Robot_Component__c recordValue : records) {
            values.add(
                recordValue.Name + ' (' +
                valueOrUnavailable(recordValue.Component_Type__c) + ', ' +
                valueOrUnavailable(recordValue.Component_Serial_Number__c) +
                '): ' + valueOrUnavailable(recordValue.Component_Status__c) +
                ', service life remaining ' +
                valueOrUnavailable(recordValue.Service_Life_Remaining__c) + 'hours'
            );
        }
        return 'Components: ' + String.join(values, ' | ');
    }

    private static String summarizeFaults(List<Robot_Fault__c> records) {
        if (records.isEmpty()) {
            return 'Open Faults: none.';
        }

        List<String> values = new List<String>();
        for (Robot_Fault__c recordValue : records) {
            values.add(
                recordValue.Name + ' (' + valueOrUnavailable(recordValue.Fault_Code__c) +
                '): ' + valueOrUnavailable(recordValue.Severity__c) + ', ' +
                valueOrUnavailable(recordValue.Fault_Status__c) + ', detected ' +
                valueOrUnavailable(recordValue.Detected_At__c)
            );
        }
        return 'Open Faults: ' + String.join(values, ' | ');
    }

    private static String summarizeMissions(List<Mission__c> records) {
        if (records.isEmpty()) {
            return 'Recent Missions: none found.';
        }

        List<String> values = new List<String>();
        for (Mission__c recordValue : records) {
            values.add(
                recordValue.Name + ' (' +
                valueOrUnavailable(recordValue.External_Mission_ID__c) + '): ' +
                valueOrUnavailable(recordValue.Mission_Type__c) + ', ' +
                valueOrUnavailable(recordValue.Mission_Status__c) + ', starts ' +
                valueOrUnavailable(recordValue.Start_Time__c)
            );
        }
        return 'Recent Missions: ' + String.join(values, ' | ');
    }

    private static String summarizeWorkOrders(
        List<Maintenance_Work_Order__c> records
    ) {
        if (records.isEmpty()) {
            return 'Open Maintenance Work Orders: none.';
        }

        List<String> values = new List<String>();
        for (Maintenance_Work_Order__c recordValue : records) {
            values.add(
                recordValue.Name + ': ' +
                valueOrUnavailable(recordValue.Work_Order_Status__c) + ', ' +
                valueOrUnavailable(recordValue.Priority__c) + ', ' +
                valueOrUnavailable(recordValue.Maintenance_Type__c) +
                ', scheduled ' + valueOrUnavailable(recordValue.Scheduled_Start__c)
            );
        }
        return 'Open Maintenance Work Orders: ' + String.join(values, ' | ');
    }

    private static String valueOrUnavailable(Object value) {
        return value == null ? 'unavailable' : String.valueOf(value);
    }
}
