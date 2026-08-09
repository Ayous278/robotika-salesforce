public with sharing class RobotIngestionService {

    public static Database.UpsertResult[] upsertRobots(
        List<Robot__c> robots
    ) {
        validateInput(robots);

        return Database.upsert(
            robots,
            Robot__c.Fields.Robot_Serial_Number__c,
            false
        );
    }

    private static void validateInput(List<Robot__c> robots) {
        if (robots == null || robots.isEmpty()) {
            throw new IllegalArgumentException(
                'At least one robot is required.'
            );
        }

        Set<String> serialNumbers = new Set<String>();

        for (Robot__c robot : robots) {
            if (robot == null) {
                throw new IllegalArgumentException(
                    'Robot records cannot be null.'
                );
            }

            if (String.isBlank(robot.Robot_Serial_Number__c)) {
                throw new IllegalArgumentException(
                    'Every robot requires a serial number.'
                );
            }

            String normalizedSerial =
                robot.Robot_Serial_Number__c.trim().toUpperCase();

            if (serialNumbers.contains(normalizedSerial)) {
                throw new IllegalArgumentException(
                    'Duplicate serial number in request: ' +
                    robot.Robot_Serial_Number__c
                );
            }

            serialNumbers.add(normalizedSerial);
            robot.Robot_Serial_Number__c =
                robot.Robot_Serial_Number__c.trim();
        }
    }
}