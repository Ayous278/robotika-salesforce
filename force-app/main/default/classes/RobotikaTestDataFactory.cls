@IsTest
public class RobotikaTestDataFactory {

    private static Integer recordSequence = 0;

    private static Integer nextSequence() {
        recordSequence++;
        return recordSequence;
    }

    public static Robot__c createRobot(Boolean insertRecord) {
        Integer sequenceNumber = nextSequence();

        Robot__c robot = new Robot__c(
            Name = 'Test Robot ' + sequenceNumber,
            Robot_Serial_Number__c =
                'TEST-ROBOT-' + sequenceNumber,
            Robot_Type__c = 'Humanoid',
            Robot_Model__c = 'Test Model',
            Operational_Status__c = 'Operational',
            Firmware_Version__c = '1.0.0',
            Total_Operating_Hours__c = 100,
            Health_Score__c = 90
        );

        if (insertRecord) {
            insert robot;
        }

        return robot;
    }

    public static Robot_Component__c createComponent(
        Id robotId,
        Decimal currentHours,
        Boolean insertRecord
    ) {
        Integer sequenceNumber = nextSequence();

        Robot_Component__c component = new Robot_Component__c(
            Robot__c = robotId,
            Component_Serial_Number__c =
                'TEST-COMPONENT-' + sequenceNumber,
            Component_Type__c = 'Battery',
            Manufacturer__c = 'Robotika Test Systems',
            Expected_Service_Life_Hours__c = 1000,
            Current_Operating_Hours__c = currentHours
        );

        if (insertRecord) {
            insert component;
        }

        return component;
    }

    public static Telemetry_Summary__c createTelemetry(
        Id robotId,
        String telemetryStatus,
        Boolean insertRecord
    ) {
        Telemetry_Summary__c telemetry =
            new Telemetry_Summary__c(
                Robot__c = robotId,
                Recorded_At__c = System.now(),
                Battery_Level__c = 75,
                CPU_Utilization__c = 45,
                CPU_Temperature_Celsius__c = 55,
                Average_Motor_Temperature_Celsius__c = 50,
                Network_Latency_Milliseconds__c = 20,
                Active_Fault_Count__c = 0,
                Telemetry_Status__c = telemetryStatus
            );

        if (insertRecord) {
            insert telemetry;
        }

        return telemetry;
    }

    public static Robot_Fault__c createFault(
        Id robotId,
        Id componentId,
        String severity,
        Boolean insertRecord
    ) {
        Integer sequenceNumber = nextSequence();

        Robot_Fault__c fault = new Robot_Fault__c(
            Robot__c = robotId,
            Robot_Component__c = componentId,
            External_Fault_ID__c =
                'TEST-FAULT-' + sequenceNumber,
            Fault_Code__c =
                'TEST_CODE_' + sequenceNumber,
            Detected_At__c = System.now(),
            Severity__c = severity,
            Fault_Status__c = 'Open',
            Fault_Description__c = 'Test fault description.'
        );

        if (insertRecord) {
            insert fault;
        }

        return fault;
    }

    public static Maintenance_Work_Order__c createWorkOrder(
        Id robotId,
        Id faultId,
        Id componentId,
        Boolean insertRecord
    ) {
        Maintenance_Work_Order__c workOrder =
            new Maintenance_Work_Order__c(
                Robot__c = robotId,
                Robot_Fault__c = faultId,
                Robot_Component__c = componentId,
                Work_Order_Status__c = 'Draft',
                Priority__c = 'Medium',
                Maintenance_Type__c = 'Inspection'
            );

        if (insertRecord) {
            insert workOrder;
        }

        return workOrder;
    }
}