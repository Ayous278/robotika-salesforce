import { createElement } from 'lwc';
import RobotTelemetryPanel from 'c/robotTelemetryPanel';

import getRecentTelemetry from
    '@salesforce/apex/RobotTelemetryService.getRecentTelemetry';

jest.mock(
    '@salesforce/apex/RobotTelemetryService.getRecentTelemetry',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');

        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

const TELEMETRY_DATA = [
    {
        Id: 'a10000000000001AAA',
        Recorded_At__c: '2026-08-09T15:00:00.000Z',
        Telemetry_Status__c: 'Critical',
        Battery_Level__c: 18,
        CPU_Utilization__c: 92,
        CPU_Temperature_Celsius__c: 91,
        Average_Motor_Temperature_Celsius__c: 84,
        Network_Latency_Milliseconds__c: 35,
        Active_Fault_Count__c: 1,
        Requires_Attention__c: true
    },
    {
        Id: 'a10000000000002AAA',
        Recorded_At__c: '2026-08-09T14:00:00.000Z',
        Telemetry_Status__c: 'Normal',
        Battery_Level__c: 73,
        CPU_Utilization__c: 48,
        CPU_Temperature_Celsius__c: 61,
        Average_Motor_Temperature_Celsius__c: 54,
        Network_Latency_Milliseconds__c: 18,
        Active_Fault_Count__c: 0,
        Requires_Attention__c: false
    }
];

function flushPromises() {
    return Promise.resolve();
}

describe('c-robot-telemetry-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(
                document.body.firstChild
            );
        }

        jest.clearAllMocks();
    });

    function createComponent() {
        const element = createElement(
            'c-robot-telemetry-panel',
            {
                is: RobotTelemetryPanel
            }
        );

        element.recordId =
            'a01000000000001AAA';

        document.body.appendChild(element);

        return element;
    }

    it('requests telemetry for the current robot', async () => {
        createComponent();

        await flushPromises();

        expect(
            getRecentTelemetry.getLastConfig()
        ).toEqual({
            robotId: 'a01000000000001AAA',
            recordLimit: 10
        });
    });

    it('renders telemetry returned by Apex', async () => {
        const element = createComponent();

        getRecentTelemetry.emit(
            TELEMETRY_DATA
        );

        await flushPromises();

        const rows =
            element.shadowRoot.querySelectorAll(
                'tbody tr'
            );

        expect(rows).toHaveLength(2);

        expect(rows[0].textContent).toContain(
            'Critical'
        );
        expect(rows[0].textContent).toContain(
            '18%'
        );
        expect(rows[0].textContent).toContain(
            '92%'
        );
        expect(rows[0].textContent).toContain(
            '91 °C'
        );
        expect(rows[0].textContent).toContain(
            '84 °C'
        );
        expect(rows[0].textContent).toContain(
            '35 ms'
        );

        expect(rows[1].textContent).toContain(
            'Normal'
        );
        expect(rows[1].textContent).toContain(
            '73%'
        );
        expect(rows[1].textContent).toContain(
            '48%'
        );
    });

    it('renders the latest telemetry summary', async () => {
        const element = createComponent();

        getRecentTelemetry.emit(
            TELEMETRY_DATA
        );

        await flushPromises();

        const summary =
            element.shadowRoot.querySelector(
                '.latest-summary'
            );

        expect(summary).not.toBeNull();
        expect(summary.textContent).toContain(
            'Critical'
        );
        expect(summary.textContent).toContain(
            '18%'
        );
        expect(summary.textContent).toContain(
            '92%'
        );
        expect(summary.textContent).toContain(
            '1'
        );
    });

    it('renders an empty state', async () => {
        const element = createComponent();

        getRecentTelemetry.emit([]);

        await flushPromises();

        const emptyState =
            element.shadowRoot.querySelector(
                '.empty-state'
            );

        expect(emptyState).not.toBeNull();
        expect(emptyState.textContent).toContain(
            'No telemetry records found'
        );
    });

    it('renders an Apex error message', async () => {
        const element = createComponent();

        getRecentTelemetry.error({
            message:
                'Telemetry request failed.'
        });

        await flushPromises();

        const alert =
            element.shadowRoot.querySelector(
                '[role="alert"]'
            );

        expect(alert).not.toBeNull();
        expect(alert.textContent).toContain(
            'Telemetry request failed.'
        );
    });
});