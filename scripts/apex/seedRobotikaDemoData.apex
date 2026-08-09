// Robotika portfolio demonstration data.
// Safe to run repeatedly: if DEMO robots exist, the script makes no changes.

Integer existingDemoRobots = [
    SELECT COUNT()
    FROM Robot__c
    WHERE Robot_Serial_Number__c LIKE 'DEMO-RBT-%'
];

if (existingDemoRobots > 0) {
    System.debug(
        LoggingLevel.WARN,
        'Robotika demo data already exists. No records were created.'
    );
} else {
    Datetime nowValue = System.now();
    Id technicianId = UserInfo.getUserId();

    List<Factory_Site__c> sites = new List<Factory_Site__c>{
        new Factory_Site__c(
            Name = 'Zurich Advanced Manufacturing Plant',
            Site_Code__c = 'DEMO-ZRH',
            Country__c = 'Switzerland',
            Site_Type__c = 'Manufacturing Plant',
            Operational_Status__c = 'Active',
            Operations_Manager__c = technicianId
        ),
        new Factory_Site__c(
            Name = 'Basel Robotics Research Center',
            Site_Code__c = 'DEMO-BSL',
            Country__c = 'Switzerland',
            Site_Type__c = 'Research Facility',
            Operational_Status__c = 'Active',
            Operations_Manager__c = technicianId
        ),
        new Factory_Site__c(
            Name = 'Geneva Distribution Hub',
            Site_Code__c = 'DEMO-GVA',
            Country__c = 'Switzerland',
            Site_Type__c = 'Distribution Center',
            Operational_Status__c = 'Limited Operations',
            Operations_Manager__c = technicianId
        )
    };
    insert sites;

    List<Robot__c> robots = new List<Robot__c>();
    List<String> robotNames = new List<String>{
        'Astra', 'Bolt', 'Cobalt', 'Delta',
        'Echo', 'Falcon', 'Gaia', 'Helix'
    };
    List<String> robotTypes = new List<String>{
        'Humanoid', 'Quadruped', 'Mobile Manipulator', 'Robotic Arm',
        'Humanoid', 'Quadruped', 'Mobile Manipulator', 'Robotic Arm'
    };
    List<String> robotModels = new List<String>{
        'H2', 'Q4', 'MM-8', 'ARM-X', 'H2', 'Q4', 'MM-8', 'ARM-X'
    };
    List<String> robotStatuses = new List<String>{
        'Operational', 'Operational', 'Degraded', 'Maintenance Required',
        'Operational', 'Unavailable', 'Degraded', 'Operational'
    };
    List<Decimal> healthScores = new List<Decimal>{
        95, 92, 70, 40, 88, 10, 68, 97
    };

    for (Integer i = 0; i < robotNames.size(); i++) {
        robots.add(new Robot__c(
            Name = robotNames[i],
            Robot_Serial_Number__c = 'DEMO-RBT-' + String.valueOf(i + 1).leftPad(3, '0'),
            Robot_Type__c = robotTypes[i],
            Robot_Model__c = robotModels[i],
            Factory_Site__c = sites[Math.mod(i, sites.size())].Id,
            Firmware_Version__c = 'v' + String.valueOf(3 + Math.mod(i, 3)) + '.2.' + i,
            Installation_Date__c = Date.today().addMonths(-(i + 3)),
            Last_Service_Date__c = Date.today().addDays(-(20 + (i * 7))),
            Next_Service_Date__c = Date.today().addDays(10 + (i * 4)),
            Total_Operating_Hours__c = 900 + (i * 425),
            Operational_Status__c = robotStatuses[i],
            Health_Score__c = healthScores[i]
        ));
    }
    insert robots;

    List<String> componentTypes = new List<String>{
        'Battery', 'Actuator', 'Motor', 'Camera', 'Compute Module', 'IMU'
    };
    List<String> manufacturers = new List<String>{
        'Robotika Energy', 'Robotika Motion', 'Robotika Motion',
        'Robotika Vision', 'Robotika Compute', 'Robotika Sensors'
    };
    List<Robot_Component__c> components = new List<Robot_Component__c>();

    for (Integer robotIndex = 0; robotIndex < robots.size(); robotIndex++) {
        for (Integer componentIndex = 0; componentIndex < componentTypes.size(); componentIndex++) {
            Decimal expectedHours = 5000 + (componentIndex * 500);
            Decimal usageRatio = 0.35 + (robotIndex * 0.07) + (componentIndex * 0.025);
            if (robotIndex == 3 && componentIndex == 1) usageRatio = 0.92;
            if (robotIndex == 5 && componentIndex == 0) usageRatio = 1.05;

            components.add(new Robot_Component__c(
                Robot__c = robots[robotIndex].Id,
                Component_Serial_Number__c =
                    'DEMO-CMP-' + String.valueOf(robotIndex + 1).leftPad(2, '0') +
                    '-' + String.valueOf(componentIndex + 1).leftPad(2, '0'),
                Component_Type__c = componentTypes[componentIndex],
                Manufacturer__c = manufacturers[componentIndex],
                Installation_Date__c = Date.today().addMonths(-(robotIndex + 2)),
                Expected_Service_Life_Hours__c = expectedHours,
                Current_Operating_Hours__c = Math.round(expectedHours * usageRatio)
            ));
        }
    }
    insert components;

    List<Mission__c> missions = new List<Mission__c>();
    List<String> missionTypes = new List<String>{
        'Inspection', 'Material Transport', 'Assembly', 'Mapping'
    };
    for (Integer robotIndex = 0; robotIndex < robots.size(); robotIndex++) {
        for (Integer missionIndex = 0; missionIndex < 2; missionIndex++) {
            Datetime startTime = nowValue.addDays(-(robotIndex + missionIndex + 1));
            missions.add(new Mission__c(
                Robot__c = robots[robotIndex].Id,
                External_Mission_ID__c =
                    'DEMO-MSN-' + String.valueOf(robotIndex + 1).leftPad(2, '0') +
                    '-' + String.valueOf(missionIndex + 1),
                Mission_Type__c = missionTypes[Math.mod(robotIndex + missionIndex, missionTypes.size())],
                Mission_Status__c = missionIndex == 0 ? 'Completed' : 'Failed',
                Start_Time__c = startTime,
                End_Time__c = startTime.addMinutes(45 + (robotIndex * 5))
            ));
        }
    }
    insert missions;

    List<String> telemetryStatuses = new List<String>{
        'Normal', 'Normal', 'Warning', 'Critical',
        'Normal', 'Offline', 'Warning', 'Normal'
    };
    List<Telemetry_Summary__c> telemetryRecords = new List<Telemetry_Summary__c>();
    for (Integer robotIndex = 0; robotIndex < robots.size(); robotIndex++) {
        for (Integer readingIndex = 0; readingIndex < 5; readingIndex++) {
            String telemetryStatus = telemetryStatuses[robotIndex];
            Decimal battery = telemetryStatus == 'Offline' ? 0 :
                telemetryStatus == 'Critical' ? 18 :
                telemetryStatus == 'Warning' ? 42 : 78 - readingIndex;
            Decimal cpu = telemetryStatus == 'Critical' ? 92 :
                telemetryStatus == 'Warning' ? 74 :
                telemetryStatus == 'Offline' ? 0 : 38 + readingIndex;

            telemetryRecords.add(new Telemetry_Summary__c(
                Robot__c = robots[robotIndex].Id,
                Mission__c = missions[robotIndex * 2].Id,
                Recorded_At__c = nowValue.addMinutes(-(readingIndex * 30)),
                Battery_Level__c = battery,
                CPU_Utilization__c = cpu,
                CPU_Temperature_Celsius__c = telemetryStatus == 'Critical' ? 91 : 55,
                Average_Motor_Temperature_Celsius__c = telemetryStatus == 'Critical' ? 84 : 50,
                Network_Latency_Milliseconds__c = telemetryStatus == 'Offline' ? null : 18 + readingIndex,
                Active_Fault_Count__c =
                    (telemetryStatus == 'Critical' || telemetryStatus == 'Offline') ? 1 : 0,
                Telemetry_Status__c = telemetryStatus
            ));
        }
    }
    insert telemetryRecords;

    List<Robot_Fault__c> faults = new List<Robot_Fault__c>();
    List<String> severities = new List<String>{
        'Low', 'Medium', 'High', 'Critical',
        'Low', 'Critical', 'High', 'Medium'
    };
    for (Integer i = 0; i < robots.size(); i++) {
        faults.add(new Robot_Fault__c(
            Robot__c = robots[i].Id,
            Robot_Component__c = components[i * 6 + Math.mod(i, 6)].Id,
            Mission__c = missions[i * 2 + 1].Id,
            External_Fault_ID__c = 'DEMO-FLT-' + String.valueOf(i + 1).leftPad(3, '0'),
            Fault_Code__c = 'RF-' + String.valueOf(200 + i),
            Fault_Description__c = 'Demonstration fault detected during robot operations.',
            Severity__c = severities[i],
            Fault_Status__c = i < 2 ? 'Investigating' : 'Open',
            Detected_At__c = nowValue.addHours(-(12 + i))
        ));
    }
    insert faults;

    List<Maintenance_Work_Order__c> workOrders = new List<Maintenance_Work_Order__c>();
    List<String> workStatuses = new List<String>{
        'Scheduled', 'In Progress', 'Waiting for Parts',
        'Completed', 'Scheduled', 'Completed'
    };
    for (Integer i = 0; i < 6; i++) {
        Datetime scheduledStart = nowValue.addDays(i - 2);
        Maintenance_Work_Order__c workOrder = new Maintenance_Work_Order__c(
            Robot__c = robots[i].Id,
            Robot_Component__c = components[i * 6].Id,
            Assigned_Technician__c = technicianId,
            Work_Order_Status__c = workStatuses[i],
            Priority__c = i == 2 ? 'High' : 'Medium',
            Maintenance_Type__c = i == 2 ? 'Component Replacement' : 'Preventive Maintenance',
            Scheduled_Start__c = scheduledStart,
            Scheduled_End__c = scheduledStart.addHours(2),
            Reminder_Sent__c = i < 2
        );

        if (workStatuses[i] == 'In Progress') {
            workOrder.Actual_Start__c = nowValue.addHours(-2);
        }
        if (workStatuses[i] == 'Completed') {
            workOrder.Actual_Start__c = scheduledStart;
            workOrder.Actual_End__c = scheduledStart.addMinutes(90);
            workOrder.Labor_Cost__c = 180 + (i * 15);
            workOrder.Parts_Cost__c = 320 + (i * 40);
            workOrder.Work_Performed__c =
                'Completed inspection, calibration, and functional verification.';
        }
        workOrders.add(workOrder);
    }
    insert workOrders;

    System.debug(LoggingLevel.INFO,
        'Robotika demo data created: ' +
        sites.size() + ' sites, ' + robots.size() + ' robots, ' +
        components.size() + ' components, ' + missions.size() + ' missions, ' +
        telemetryRecords.size() + ' telemetry records, ' + faults.size() +
        ' faults, and ' + workOrders.size() + ' manually seeded work orders. ' +
        'Critical-fault automation may add two more work orders.'
    );
}
