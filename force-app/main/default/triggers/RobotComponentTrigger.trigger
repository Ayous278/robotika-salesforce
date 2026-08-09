trigger RobotComponentTrigger on Robot_Component__c (
    before insert,
    before update
) {
    RobotComponentStatusService.applyStatus(Trigger.new);
}