@IsTest
private class RobotDiagnosticsClientTest {

    private class DiagnosticsHttpMock
        implements HttpCalloutMock {

        private Integer statusCode;
        private String status;
        private String responseBody;

        DiagnosticsHttpMock(
            Integer statusCode,
            String status,
            String responseBody
        ) {
            this.statusCode = statusCode;
            this.status = status;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            System.assertEquals(
                'GET',
                request.getMethod(),
                'The diagnostics request must use GET.'
            );

            System.assertEquals(
                'application/json',
                request.getHeader('Accept'),
                'The client must request JSON.'
            );

            System.assert(
                request.getEndpoint().endsWith(
                    '/v1/robots/HR-107/diagnostics'
                ),
                'The endpoint must contain the encoded robot serial number.'
            );

            HttpResponse response = new HttpResponse();

            response.setStatusCode(statusCode);
            response.setStatus(status);
            response.setHeader(
                'Content-Type',
                'application/json'
            );
            response.setBody(responseBody);

            return response;
        }
    }

    @IsTest
    static void returnsSuccessfulDiagnostics() {
        String responseBody = JSON.serialize(
            new Map<String, Object>{
                'robotSerialNumber' => 'HR-107',
                'diagnosticStatus' => 'Degraded',
                'recommendedHealthScore' => 68,
                'maintenanceRecommended' => true,
                'diagnosticMessage' =>
                    'Battery performance is below expected range.'
            }
        );

        Test.setMock(
            HttpCalloutMock.class,
            new DiagnosticsHttpMock(
                200,
                'OK',
                responseBody
            )
        );

        Test.startTest();

        RobotDiagnosticsClient.DiagnosticResult result =
            RobotDiagnosticsClient.requestDiagnostics(
                'HR-107'
            );

        Test.stopTest();

        System.assertEquals(
            'HR-107',
            result.robotSerialNumber
        );

        System.assertEquals(
            'Degraded',
            result.diagnosticStatus
        );

        System.assertEquals(
            68,
            result.recommendedHealthScore
        );

        System.assertEquals(
            true,
            result.maintenanceRecommended
        );

        System.assertEquals(
            'Battery performance is below expected range.',
            result.diagnosticMessage
        );
    }

    @IsTest
    static void rejectsBlankSerialNumber() {
        Test.startTest();

        try {
            RobotDiagnosticsClient.requestDiagnostics(' ');

            System.assert(
                false,
                'A blank serial number should throw an exception.'
            );
        } catch (
            RobotDiagnosticsClient.RobotDiagnosticsException
                exceptionValue
        ) {
            System.assertEquals(
                'A robot serial number is required.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void handlesHttpFailure() {
        Test.setMock(
            HttpCalloutMock.class,
            new DiagnosticsHttpMock(
                503,
                'Service Unavailable',
                '{"message":"Temporarily unavailable"}'
            )
        );

        Test.startTest();

        try {
            RobotDiagnosticsClient.requestDiagnostics(
                'HR-107'
            );

            System.assert(
                false,
                'An unsuccessful response should throw an exception.'
            );
        } catch (
            RobotDiagnosticsClient.RobotDiagnosticsException
                exceptionValue
        ) {
            System.assert(
                exceptionValue.getMessage().contains('503'),
                'The exception should include the HTTP status code.'
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void handlesInvalidJson() {
        Test.setMock(
            HttpCalloutMock.class,
            new DiagnosticsHttpMock(
                200,
                'OK',
                'This is not valid JSON'
            )
        );

        Test.startTest();

        try {
            RobotDiagnosticsClient.requestDiagnostics(
                'HR-107'
            );

            System.assert(
                false,
                'Invalid JSON should throw an exception.'
            );
        } catch (
            RobotDiagnosticsClient.RobotDiagnosticsException
                exceptionValue
        ) {
            System.assertEquals(
                'The diagnostics service returned invalid JSON.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void handlesMissingRequiredData() {
        Test.setMock(
            HttpCalloutMock.class,
            new DiagnosticsHttpMock(
                200,
                'OK',
                '{"robotSerialNumber":"HR-107"}'
            )
        );

        Test.startTest();

        try {
            RobotDiagnosticsClient.requestDiagnostics(
                'HR-107'
            );

            System.assert(
                false,
                'Missing required data should throw an exception.'
            );
        } catch (
            RobotDiagnosticsClient.RobotDiagnosticsException
                exceptionValue
        ) {
            System.assertEquals(
                'The diagnostics response is missing required data.',
                exceptionValue.getMessage()
            );
        }

        Test.stopTest();
    }
}