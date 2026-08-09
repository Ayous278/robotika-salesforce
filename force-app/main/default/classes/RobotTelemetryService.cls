public with sharing class RobotTelemetryService {

    @AuraEnabled(cacheable=true)
    public static List<Telemetry_Summary__c> getRecentTelemetry(
        Id robotId,
        Integer recordLimit
    ) {
        if (robotId == null) {
            throw new IllegalArgumentException(
                'A Robot record ID is required.'
            );
        }

        if (
            recordLimit == null ||
            recordLimit < 1 ||
            recordLimit > 50
        ) {
            throw new IllegalArgumentException(
                'Record limit must be between 1 and 50.'
            );
        }

        return [
            SELECT
                Id,
                Name,
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
            WHERE Robot__c = :robotId
            WITH USER_MODE
            ORDER BY Recorded_At__c DESC
            LIMIT :recordLimit
        ];
    }
}