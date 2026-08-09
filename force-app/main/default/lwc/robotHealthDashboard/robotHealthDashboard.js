import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import getRobotsNeedingAttention from
    '@salesforce/apex/RobotHealthService.getRobotsNeedingAttention';

export default class RobotHealthDashboard extends NavigationMixin(
    LightningElement
) {
    maximumHealthScore = 80;
    robots = [];
    errorMessage;
    isLoading = true;
    wiredRobotsResult;

    @wire(getRobotsNeedingAttention, {
        maximumHealthScore: '$maximumHealthScore'
    })
    wiredRobots(result) {
        this.wiredRobotsResult = result;

        const { data, error } = result;

        if (data) {
            this.robots = data.map((robot) => {
                const healthScore =
                    robot.Health_Score__c == null
                        ? 0
                        : robot.Health_Score__c;

                return {
                    id: robot.Id,
                    name: robot.Name,
                    serialNumber:
                        robot.Robot_Serial_Number__c || 'No serial number',
                    robotType:
                        robot.Robot_Type__c || 'Not specified',
                    operationalStatus:
                        robot.Operational_Status__c || 'Unknown',
                    healthScore,
                    totalComponents:
                        robot.Total_Components__c == null
                            ? 0
                            : robot.Total_Components__c,
                    progressVariant:
                        healthScore < 50
                            ? 'expired'
                            : 'base'
                };
            });

            this.errorMessage = undefined;
            this.isLoading = false;
        } else if (error) {
            this.robots = [];
            this.errorMessage =
                this.getErrorMessage(error);
            this.isLoading = false;
        }
    }

    get hasRobots() {
        return this.robots.length > 0;
    }

    get robotCount() {
        return this.robots.length;
    }

    handleThresholdChange(event) {
        const newThreshold =
            Number(event.target.value);

        if (
            Number.isInteger(newThreshold) &&
            newThreshold >= 0 &&
            newThreshold <= 100
        ) {
            this.isLoading = true;
            this.maximumHealthScore = newThreshold;
        }
    }

    async handleRefresh() {
        this.isLoading = true;

        try {
            await refreshApex(
                this.wiredRobotsResult
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleRobotNavigation(event) {
        const recordId =
            event.currentTarget.dataset.recordId;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Robot__c',
                actionName: 'view'
            }
        });
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return 'The robot health data could not be loaded.';
    }
}