public with sharing class RobotHealthService {
    @AuraEnabled(cacheable=true)
    public static List<Robot__c> getRobotsNeedingAttention(
        Integer maximumHealthScore
    ) {
        validateHealthThreshold(maximumHealthScore);

        return [
            SELECT
                Id,
                Name,
                Robot_Serial_Number__c,
                Robot_Type__c,
                Operational_Status__c,
                Health_Score__c,
                Total_Components__c
            FROM Robot__c
            WHERE
                Health_Score__c <= :maximumHealthScore
                OR Operational_Status__c IN (
                    'Degraded',
                    'Maintenance Required',
                    'Unavailable'
                )
            ORDER BY Health_Score__c ASC NULLS LAST
        ];
    }

    private static void validateHealthThreshold(Integer maximumHealthScore) {
        if (
            maximumHealthScore == null ||
            maximumHealthScore < 0 ||
            maximumHealthScore > 100
        ) {
            throw new IllegalArgumentException(
                'Maximum health score must be between 0 and 100.'
            );
        }
    }
}