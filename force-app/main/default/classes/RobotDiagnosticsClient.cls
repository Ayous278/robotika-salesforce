public with sharing class RobotDiagnosticsClient {

    @TestVisible
    private static final String BASE_ENDPOINT =
        'https://api.robotika.example';

    public class RobotDiagnosticsException extends Exception {
    }

    public class DiagnosticResult {
        public String robotSerialNumber;
        public String diagnosticStatus;
        public Decimal recommendedHealthScore;
        public Boolean maintenanceRecommended;
        public String diagnosticMessage;
    }

    public static DiagnosticResult requestDiagnostics(
        String robotSerialNumber
    ) {
        if (String.isBlank(robotSerialNumber)) {
            throw new RobotDiagnosticsException(
                'A robot serial number is required.'
            );
        }

        HttpRequest request = new HttpRequest();

        request.setEndpoint(
            BASE_ENDPOINT +
            '/v1/robots/' +
            EncodingUtil.urlEncode(
                robotSerialNumber,
                'UTF-8'
            ) +
            '/diagnostics'
        );

        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        request.setTimeout(10000);

        HttpResponse response =
            new Http().send(request);

        if (response.getStatusCode() < 200 ||
            response.getStatusCode() >= 300) {

            throw new RobotDiagnosticsException(
                'Diagnostics service returned HTTP ' +
                response.getStatusCode() +
                ': ' +
                response.getStatus()
            );
        }

        Map<String, Object> responseBody;

        try {
            responseBody =
                (Map<String, Object>) JSON.deserializeUntyped(
                    response.getBody()
                );
        } catch (Exception exceptionValue) {
            throw new RobotDiagnosticsException(
                'The diagnostics service returned invalid JSON.'
            );
        }

        if (responseBody == null ||
            !responseBody.containsKey('diagnosticStatus')) {

            throw new RobotDiagnosticsException(
                'The diagnostics response is missing required data.'
            );
        }

        DiagnosticResult result =
            new DiagnosticResult();

        result.robotSerialNumber =
            (String) responseBody.get('robotSerialNumber');

        result.diagnosticStatus =
            (String) responseBody.get('diagnosticStatus');

        result.recommendedHealthScore =
            responseBody.get('recommendedHealthScore') == null
                ? null
                : Decimal.valueOf(
                    String.valueOf(
                        responseBody.get(
                            'recommendedHealthScore'
                        )
                    )
                );

        result.maintenanceRecommended =
            responseBody.get('maintenanceRecommended') == null
                ? false
                : (Boolean) responseBody.get(
                    'maintenanceRecommended'
                );

        result.diagnosticMessage =
            (String) responseBody.get('diagnosticMessage');

        return result;
    }
}