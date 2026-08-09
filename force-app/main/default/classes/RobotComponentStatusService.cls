public with sharing class RobotComponentStatusService {
    
    @AuraEnabled(cacheable=true)
    private static final Decimal WARNING_USAGE_RATIO = 0.80;

    public static void applyStatus(
        List<Robot_Component__c> components
    ) {
        if (components == null) {
            return;
        }

        for (Robot_Component__c component : components) {
            if (component == null) {
                continue;
            }

            if (
                component.Component_Status__c == 'Failed' ||
                component.Component_Status__c == 'Replaced'
            ) {
                continue;
            }

            Decimal expectedHours =
                component.Expected_Service_Life_Hours__c;
            Decimal currentHours =
                component.Current_Operating_Hours__c;

            if (
                expectedHours == null ||
                expectedHours <= 0 ||
                currentHours == null
            ) {
                continue;
            }

            Decimal usageRatio = currentHours / expectedHours;

            if (currentHours >= expectedHours) {
                component.Component_Status__c =
                    'Maintenance Required';
            } else if (usageRatio >= WARNING_USAGE_RATIO) {
                component.Component_Status__c = 'Warning';
            } else {
                component.Component_Status__c = 'Healthy';
            }
        }
    }
}