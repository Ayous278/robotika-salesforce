import { api, LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getRecentTelemetry from
    '@salesforce/apex/RobotTelemetryService.getRecentTelemetry';

export default class RobotTelemetryPanel extends LightningElement {
    @api recordId;
    @api recordLimit = 10;

    telemetryRecords = [];
    errorMessage;
    isLoading = true;
    wiredTelemetryResult;

    @wire(getRecentTelemetry, {
        robotId: '$recordId',
        recordLimit: '$recordLimit'
    })
    wiredTelemetry(result) {
        this.wiredTelemetryResult = result;

        const { data, error } = result;

        if (data) {
            this.telemetryRecords =
                data.map((telemetry) =>
                    this.formatTelemetry(telemetry)
                );

            this.errorMessage = undefined;
            this.isLoading = false;
        } else if (error) {
            this.telemetryRecords = [];
            this.errorMessage =
                this.getErrorMessage(error);
            this.isLoading = false;
        }
    }

    get hasTelemetry() {
        return this.telemetryRecords.length > 0;
    }

    get latestTelemetry() {
        return this.hasTelemetry
            ? this.telemetryRecords[0]
            : undefined;
    }

    async handleRefresh() {
        this.isLoading = true;

        try {
            await refreshApex(
                this.wiredTelemetryResult
            );
        } finally {
            this.isLoading = false;
        }
    }

    formatTelemetry(telemetry) {
        const batteryPercentage =
            this.toPercentage(
                telemetry.Battery_Level__c
            );

        const cpuPercentage =
            this.toPercentage(
                telemetry.CPU_Utilization__c
            );

        const activeFaultCount =
            telemetry.Active_Fault_Count__c == null
                ? 0
                : telemetry.Active_Fault_Count__c;

        const status =
            telemetry.Telemetry_Status__c || 'Unknown';

        return {
            id: telemetry.Id,
            recordedAt: telemetry.Recorded_At__c,
            status,
            statusClass:
                this.getStatusClass(
                    status,
                    telemetry.Requires_Attention__c
                ),
            batteryPercentage,
            cpuPercentage,
            cpuTemperature:
                this.formatTemperature(
                    telemetry.CPU_Temperature_Celsius__c
                ),
            motorTemperature:
                this.formatTemperature(
                    telemetry
                        .Average_Motor_Temperature_Celsius__c
                ),
            networkLatency:
                this.formatLatency(
                    telemetry
                        .Network_Latency_Milliseconds__c
                ),
            activeFaultCount,
            faultClass:
                activeFaultCount > 0
                    ? 'fault-count fault-count_alert'
                    : 'fault-count'
        };
    }

    toPercentage(value) {
        if (value == null) {
            return 0;
        }

        return Math.round(
            Number(value)
        );
    }

    formatTemperature(value) {
        return value == null
            ? '—'
            : `${value} °C`;
    }

    formatLatency(value) {
        return value == null
            ? '—'
            : `${value} ms`;
    }

    getStatusClass(status, requiresAttention) {
        if (
            status === 'Critical' ||
            status === 'Offline'
        ) {
            return 'status status_critical';
        }

        if (
            status === 'Warning' ||
            requiresAttention
        ) {
            return 'status status_warning';
        }

        return 'status status_normal';
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return 'Telemetry data could not be loaded.';
    }
}