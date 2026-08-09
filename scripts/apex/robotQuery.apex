List<Robot__c> robots = [
    SELECT
        Id,
        Name,
        Robot_Serial_Number__c,
        Robot_Type__c,
        Operational_Status__c,
        Health_Score__c,
        Total_Components__c
    FROM Robot__c
    ORDER BY Name
];

System.debug('Number of robots: ' + robots.size());

for (Robot__c robot : robots) {
    System.debug(
        'Robot: ' + robot.Name +
        ' | Serial: ' + robot.Robot_Serial_Number__c +
        ' | Status: ' + robot.Operational_Status__c +
        ' | Health: ' + robot.Health_Score__c +
        ' | Components: ' + robot.Total_Components__c
    );
}