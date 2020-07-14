using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;

class ProfileManager {
    public const ONEWHEEL_SERVICE = Ble.stringToUuid("e659f300-ea98-11e3-ac10-0800200c9a66");

    public const SERIAL_NUMBER_CHARACTERISTIC = Ble.stringToUuid("e659F301-ea98-11e3-ac10-0800200c9a66"); //2085
    public const RIDING_MODE_CHARACTERISTIC = Ble.stringToUuid("e659f302-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_REMAINING_CHARACTERISTIC = Ble.stringToUuid("e659f303-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_LOW_5_CHARACTERISTIC = Ble.stringToUuid("e659f304-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_LOW_20_CHARACTERISTIC = Ble.stringToUuid("e659f305-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_SERIAL_CHARACTERISTIC = Ble.stringToUuid("e659f306-ea98-11e3-ac10-0800200c9a66"); //22136
    public const TILT_ANGLE_PITCH_CHARACTERISTIC = Ble.stringToUuid("e659f307-ea98-11e3-ac10-0800200c9a66");
    public const TILT_ANGLE_ROLL_CHARACTERISTIC = Ble.stringToUuid("e659f308-ea98-11e3-ac10-0800200c9a66");
    public const TILT_ANGLE_YAW_CHARACTERISTIC = Ble.stringToUuid("e659f309-ea98-11e3-ac10-0800200c9a66");
    public const TEMPERATURE_CHARACTERISTIC = Ble.stringToUuid("e659f310-ea98-11e3-ac10-0800200c9a66");
    public const STATUS_ERROR_CHARACTERISTIC = Ble.stringToUuid("e659f30f-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_CELLS_CHARACTERISTIC = Ble.stringToUuid("e659f31b-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_TEMP_CHARACTERISTIC = Ble.stringToUuid("e659f315-ea98-11e3-ac10-0800200c9a66");
    public const BATTERY_VOLTAGE_CHARACTERISTIC = Ble.stringToUuid("e659f316-ea98-11e3-ac10-0800200c9a66");
    public const CURRENT_AMPS_CHARACTERISTIC = Ble.stringToUuid("e659f312-ea98-11e3-ac10-0800200c9a66");
    public const CUSTOM_NAME_CHARACTERISTIC = Ble.stringToUuid("e659f3fd-ea98-11e3-ac10-0800200c9a66");
    public const FIRMWARE_REVISION_CHARACTERISTIC = Ble.stringToUuid("e659f311-ea98-11e3-ac10-0800200c9a66"); //3034
    public const HARDWARE_REVISION_CHARACTERISTIC = Ble.stringToUuid("e659f318-ea98-11e3-ac10-0800200c9a66"); //2206
    public const LAST_ERROR_CODE_CHARACTERISTIC = Ble.stringToUuid("e659f31c-ea98-11e3-ac10-0800200c9a66");
    public const LIFETIME_AMP_HOURS_CHARACTERISTIC = Ble.stringToUuid("e659f31a-ea98-11e3-ac10-0800200c9a66");
    public const LIFETIME_ODOMETER_CHARACTERISTIC = Ble.stringToUuid("e659f319-ea98-11e3-ac10-0800200c9a66");
    public const LIGHTING_MODE_CHARACTERISTIC = Ble.stringToUuid("e659f30c-ea98-11e3-ac10-0800200c9a66");
    public const LIGHTS_BACK_CHARACTERISTIC = Ble.stringToUuid("e659f30e-ea98-11e3-ac10-0800200c9a66");
    public const LIGHTS_FRONT_CHARACTERISTIC = Ble.stringToUuid("e659f30d-ea98-11e3-ac10-0800200c9a66");
    public const ODOMETER_CHARACTERISTIC = Ble.stringToUuid("e659f30a-ea98-11e3-ac10-0800200c9a66");
    public const SAFETY_HEADROOM_CHARACTERISTIC = Ble.stringToUuid("e659f317-ea98-11e3-ac10-0800200c9a66");
    public const SPEED_RPM_CHARACTERISTIC = Ble.stringToUuid("e659f30b-ea98-11e3-ac10-0800200c9a66");
    public const TRIP_REGEN_AMP_HOURS_CHARACTERISTIC = Ble.stringToUuid("e659f314-ea98-11e3-ac10-0800200c9a66");
    public const TRIP_TOTAL_AMP_HOURS_CHARACTERISTIC = Ble.stringToUuid("e659f313-ea98-11e3-ac10-0800200c9a66");
    public const UART_SERIAL_READ_CHARACTERISTIC = Ble.stringToUuid("e659f3fe-ea98-11e3-ac10-0800200c9a66");
    public const UART_SERIAL_WRITE_CHARACTERISTIC = Ble.stringToUuid("e659f3ff-ea98-11e3-ac10-0800200c9a66");
    public const UNKNOWN1_CHARACTERISTIC = Ble.stringToUuid("e659f31d-ea98-11e3-ac10-0800200c9a66");
    public const UNKNOWN2_CHARACTERISTIC = Ble.stringToUuid("e659f31e-ea98-11e3-ac10-0800200c9a66");
    public const UNKNOWN3_CHARACTERISTIC = Ble.stringToUuid("e659f31f-ea98-11e3-ac10-0800200c9a66");
    public const UNKNOWN4_CHARACTERISTIC = Ble.stringToUuid("e659f320-ea98-11e3-ac10-0800200c9a66");

    private const _onewheelProfileDef = {
        :uuid => ONEWHEEL_SERVICE,
        :characteristics => [{
            :uuid => FIRMWARE_REVISION_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => UART_SERIAL_READ_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => UART_SERIAL_WRITE_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => BATTERY_REMAINING_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => SAFETY_HEADROOM_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => SPEED_RPM_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }, {
            :uuid => ODOMETER_CHARACTERISTIC,
            :descriptors => [
                Ble.cccdUuid()
            ]
        }]
    };

    function registerProfiles() {
        var ret = Ble.registerProfile(_onewheelProfileDef);
    }

    function getMonitoredCharacteristicUuids() {
        return [
            BATTERY_REMAINING_CHARACTERISTIC,
            ODOMETER_CHARACTERISTIC,
            SPEED_RPM_CHARACTERISTIC,
        ];
    }

    function getInitialReadCharacteristicUuids() {
        return [
            ODOMETER_CHARACTERISTIC,
            BATTERY_REMAINING_CHARACTERISTIC,
        ];
    }
}
