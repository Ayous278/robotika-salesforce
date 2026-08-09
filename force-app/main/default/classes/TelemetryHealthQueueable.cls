public class TelemetryHealthQueueable implements Queueable {

    private Set<Id> telemetryIds;

    public TelemetryHealthQueueable(Set<Id> telemetryIds) {
        this.telemetryIds = telemetryIds == null
            ? new Set<Id>()
            : new Set<Id>(telemetryIds);
    }

    public void execute(QueueableContext context) {
        if (telemetryIds.isEmpty()) {
            return;
        }

        List<Telemetry_Summary__c> telemetryRecords = [
            SELECT
                Id,
                Robot__c,
                Telemetry_Status__c,
                Requires_Attention__c
            FROM Telemetry_Summary__c
            WHERE Id IN :telemetryIds
        ];

        Map<Id, Decimal> scoreByRobotId =
            new Map<Id, Decimal>();

        for (Telemetry_Summary__c telemetry : telemetryRecords) {
            if (telemetry.Robot__c == null) {
                continue;
            }

            Decimal telemetryScore =
                calculateTelemetryScore(telemetry);

            if (
                !scoreByRobotId.containsKey(telemetry.Robot__c) ||
                telemetryScore <
                    scoreByRobotId.get(telemetry.Robot__c)
            ) {
                scoreByRobotId.put(
                    telemetry.Robot__c,
                    telemetryScore
                );
            }
        }

        List<Robot__c> robotsToUpdate = new List<Robot__c>();

        for (Id robotId : scoreByRobotId.keySet()) {
            robotsToUpdate.add(
                new Robot__c(
                    Id = robotId,
                    Health_Score__c =
                        scoreByRobotId.get(robotId)
                )
            );
        }

        if (!robotsToUpdate.isEmpty()) {
            Database.update(robotsToUpdate, false);
        }
    }

    @TestVisible
    private static Decimal calculateTelemetryScore(
        Telemetry_Summary__c telemetry
    ) {
        if (telemetry.Telemetry_Status__c == 'Offline') {
            return 10;
        }

        if (telemetry.Telemetry_Status__c == 'Critical') {
            return 40;
        }

        if (
            telemetry.Telemetry_Status__c == 'Warning' ||
            telemetry.Requires_Attention__c
        ) {
            return 70;
        }

        return 95;
    }
}