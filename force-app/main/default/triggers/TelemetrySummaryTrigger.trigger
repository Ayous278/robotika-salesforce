trigger TelemetrySummaryTrigger on Telemetry_Summary__c (
    after insert
) {
    Set<Id> telemetryIds =
        new Map<Id, Telemetry_Summary__c>(Trigger.new).keySet();

    if (!telemetryIds.isEmpty()) {
        System.enqueueJob(
            new TelemetryHealthQueueable(telemetryIds)
        );
    }
}