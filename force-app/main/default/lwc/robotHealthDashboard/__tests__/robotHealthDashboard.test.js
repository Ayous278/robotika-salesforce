import { createElement } from 'lwc';
import RobotHealthDashboard from 'c/robotHealthDashboard';

import getRobotsNeedingAttention from
    '@salesforce/apex/RobotHealthService.getRobotsNeedingAttention';

jest.mock(
    '@salesforce/apex/RobotHealthService.getRobotsNeedingAttention',
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

const ROBOT_DATA = [
    {
        Id: 'a01000000000001AAA',
        Name: 'Atlas One',
        Robot_Serial_Number__c: 'HR-107',
        Robot_Type__c: 'Humanoid',
        Operational_Status__c: 'Unavailable',
        Health_Score__c: 86,
        Total_Components__c: 6
    }
];

function flushPromises() {
    return Promise.resolve();
}

describe('c-robot-health-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(
                document.body.firstChild
            );
        }

        jest.clearAllMocks();
    });

    it('renders robots returned by Apex', async () => {
        const element = createElement(
            'c-robot-health-dashboard',
            {
                is: RobotHealthDashboard
            }
        );

        document.body.appendChild(element);

        getRobotsNeedingAttention.emit(ROBOT_DATA);

        await flushPromises();

        const robotCard =
            element.shadowRoot.querySelector(
                '.robot-card'
            );

        expect(robotCard).not.toBeNull();
        expect(robotCard.textContent).toContain(
            'Atlas One'
        );
        expect(robotCard.textContent).toContain(
            'HR-107'
        );
        expect(robotCard.textContent).toContain(
            'Humanoid'
        );
        expect(robotCard.textContent).toContain(
            '86%'
        );
        expect(robotCard.textContent).toContain(
            '6'
        );

        const progressBar =
            element.shadowRoot.querySelector(
                'lightning-progress-bar'
            );

        expect(progressBar.value).toBe(86);
    });

    it('renders the empty state when no robots match', async () => {
        const element = createElement(
            'c-robot-health-dashboard',
            {
                is: RobotHealthDashboard
            }
        );

        document.body.appendChild(element);

        getRobotsNeedingAttention.emit([]);

        await flushPromises();

        const emptyState =
            element.shadowRoot.querySelector(
                '.empty-state'
            );

        expect(emptyState).not.toBeNull();
        expect(emptyState.textContent).toContain(
            'No robots need attention'
        );

        expect(
            element.shadowRoot.querySelector(
                '.robot-card'
            )
        ).toBeNull();
    });

    it('renders an Apex error message', async () => {
        const element = createElement(
            'c-robot-health-dashboard',
            {
                is: RobotHealthDashboard
            }
        );

        document.body.appendChild(element);

        getRobotsNeedingAttention.error({
        message:
            'The robot health data could not be retrieved.'
        });

        await flushPromises();

        const alert =
            element.shadowRoot.querySelector(
                '[role="alert"]'
            );

        expect(alert).not.toBeNull();
        expect(alert.textContent).toContain(
            'The robot health data could not be retrieved.'
        );
    });

    it('uses 80 as the initial health threshold', async () => {
        const element = createElement(
            'c-robot-health-dashboard',
            {
                is: RobotHealthDashboard
            }
        );

        document.body.appendChild(element);

        await flushPromises();

        expect(
            getRobotsNeedingAttention.getLastConfig()
        ).toEqual({
            maximumHealthScore: 80
        });
    });

    it('updates the threshold after valid user input', async () => {
        const element = createElement(
            'c-robot-health-dashboard',
            {
                is: RobotHealthDashboard
            }
        );

        document.body.appendChild(element);

        const thresholdInput =
            element.shadowRoot.querySelector(
                'lightning-input'
            );

        thresholdInput.value = '65';

        thresholdInput.dispatchEvent(
            new CustomEvent('change')
        );

        await flushPromises();

        expect(
            getRobotsNeedingAttention.getLastConfig()
        ).toEqual({
            maximumHealthScore: 65
        });
    });
});