using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as Sys;
using Toybox.WatchUi as WatchUi;

// Next: Figure out why onDescriptorWrite is getting called after all is said
//       and done.
class OWDataModel {
    private var _profileManager;

    private var _device;
    private var _service;
    private var _isConnected;
    private var _initialized;

    private var _tiltAnglePitch;
    private var _batteryRemaining;
    private var _safetyHeadroom;
    private var _speedMph;
    private var _odometer;
    private var _lifetimeOdometer;

    private var _pendingReads;
    private var _pendingNotifies;

    function initialize(bleDelegate,
                        profileManager,
                        connectionManager) {
        _profileManager = profileManager;

        _device = null;
        _isConnected = false;
        _initialized = false;

        _speedMph = 0.0;

        connectionManager.notifyConnected(method(:notifyConnected));

        bleDelegate.notifyOnConnectedStateChanged(
                method(:onConnectedStateChanged));
        bleDelegate.notifyOnDescriptorWrite(method(:onDescriptorWrite));
        bleDelegate.notifyOnCharacteristicChanged(
                method(:onCharacteristicChanged));
        bleDelegate.notifyOnCharacteristicRead(method(:onCharacteristicRead));
        _pendingNotifies = [];
        _pendingReads = [];
    }

    function isConnected() {
        return _initialized;
    }

    function onConnectedStateChanged(device, state) {
        if (state == Ble.CONNECTION_STATE_DISCONNECTED) {
            Utils.log("OWDataModel: Onewheel disconnected, resetting state.");
            _isConnected = false;
            _service = null;
        }
    }

    function notifyConnected(device) {
        Utils.log("Onewheel connected.");
        // OW is connected. Queue characteristics to be notified about.
        _isConnected = true;
        _service = device.getService(_profileManager.ONEWHEEL_SERVICE);
        queueNotifications();
        activateNextNotification();
    }

    private function queueNotifications() {
        Utils.log("Queuing characteristic notifications");
        var monitoredCharacteristicUuids =
                _profileManager.getMonitoredCharacteristicUuids();
        for (var i = 0; i < monitoredCharacteristicUuids.size(); ++i) {
            var characteristic = _service.getCharacteristic(
                    monitoredCharacteristicUuids[i]);
            if (characteristic == null) {
                System.println("Couldn't find characteristic with uuid: " +
                               monitoredCharacteristicUuids[i]);
                continue;
            }
            _pendingNotifies.add(characteristic);
        }
    }

    private function activateNextNotification() {
        if (_pendingNotifies.size() == 0) {
            return;
        }

        requestNotification(_pendingNotifies[0]);
    }

    private function requestNotification(characteristic) {
        Utils.log("Requesting notification for characteristic with Uuid: " +
                    characteristic.getUuid());
        var cccd = characteristic.getDescriptor(Ble.cccdUuid());
        if (cccd == null) {
            Utils.log("Couldn't get cccd descriptor for characteristic " +
                        "with uuid: " + characteristic.getUuid());
            return;
        }
        try {
            cccd.requestWrite([0x01, 0x00]b);
        } catch (ex) {
            Utils.log("Caught exception while requesting notification for " +
                      "uuid: " + characteristic.getUuid() + " error: " + ex.getErrorMessage());
            ex.printStackTrace();
            Sys.exit();
        }
    }

    function onDescriptorWrite(descriptor, status) {
        if (!_isConnected) {
            Utils.log("OWDataModel: onDescriptorWrite called for uuid: " +
                      descriptor.getCharacteristic().getUuid() +
                      " but skipping, since not connected yet.");
            return;
        }
        Utils.log("OWDataModel: onDescriptorWrite called for uuid: " +
                  descriptor.getCharacteristic().getUuid());

        if (!descriptor.getCharacteristic().getUuid().equals(
                _pendingNotifies[0].getUuid())) {
            Utils.log("OWDataModel: Not the descriptor write we're waiting " +
                      "for, returning.");
            return;
        }
        if (status != Ble.STATUS_SUCCESS) {
            Utils.log("Descriptor write failed, retrying.");
            activateNextNotification();
            return;
        }

        Utils.log("Notification request completed.");
        if (_pendingNotifies.size() > 1) {
            _pendingNotifies = _pendingNotifies.slice(1,
                                                      _pendingNotifies.size());
            activateNextNotification();
        } else if (_pendingNotifies.size() == 1) {
            Utils.log("Finished requesting all notifications.");
            _pendingNotifies = [];
            queueReads();
            activateNextRead();
        }
    }

    private function queueReads() {
        Utils.log("Queuing initial reads.");
        var readUuids =
                _profileManager.getInitialReadCharacteristicUuids();
        for (var i = 0; i < readUuids.size(); ++i) {
            var characteristic = _service.getCharacteristic(readUuids[i]);
            if (characteristic == null) {
                System.println("Couldn't find characteristic with uuid: " +
                              readUuids[i]);
                continue;
            }
            _pendingReads.add(characteristic);
        }
    }

    private function activateNextRead() {
        if (_pendingReads.size() == 0) {
            return;
        }
        Utils.log("Requesting read of characteristic with uuid: " +
                    _pendingReads[0].getUuid());
        _pendingReads[0].requestRead();
    }

    function onCharacteristicChanged(characteristic, value) {
        if (!_isConnected) {
            return;
        }
        switch (characteristic.getUuid()) {
            case _profileManager.BATTERY_REMAINING_CHARACTERISTIC:
                processBatteryRemaining(value);
                break;
            case _profileManager.SPEED_RPM_CHARACTERISTIC:
                processSpeedRpm(value);
                break;
            case _profileManager.ODOMETER_CHARACTERISTIC:
                processOdometer(value);
                break;
        }
    }

    function onCharacteristicRead(characteristic, status, value) {
        if (!_isConnected) {
            return;
        }
        if (status != Ble.STATUS_SUCCESS) {
            Utils.log("Failed to read characeristic with Uuid: " +
                      characteristic.getUuid() + " with status: " + status +
                      ", retrying.");
            activateNextRead();
        } else {
            Utils.log("Received response for characteristic read.");
            switch (characteristic.getUuid()) {
                // Add cases
                case _profileManager.BATTERY_REMAINING_CHARACTERISTIC:
                    processBatteryRemaining(value);
                    break;
                case _profileManager.ODOMETER_CHARACTERISTIC:
                    processOdometer(value);
                    break;
            }
        }
        if (_pendingReads.size() > 1) {
            _pendingReads = _pendingReads.slice(1, _pendingReads.size());
            activateNextRead();
        } else {
            _pendingReads = [];
            _initialized = true;
            Utils.log("All done with initial reads.");
        }
    }

    function getTiltAnglePitch() {
        return _tiltAnglePitch;
    }

    function getBatteryRemaining() {
        return _batteryRemaining;
    }

    function getSafetyHeadroom() {
        return _safetyHeadroom;
    }

    function getSpeedMph() {
        return _speedMph;
    }

    function getOdometer() {
        return _odometer;
    }

    private function processTiltAnglePitch(value) {
        _tiltAnglePitch = value.decodeNumber(
                Lang.NUMBER_FORMAT_UINT16,
                { :endianness => Lang.ENDIAN_BIG });
        Utils.log("Pitch changed. Raw = " + value + " decoded: " + _tiltAnglePitch);
        WatchUi.requestUpdate();
    }

    private function processBatteryRemaining( value ) {
        _batteryRemaining = value.decodeNumber(Lang.NUMBER_FORMAT_UINT8,
                                               {:offset => 1});
        Utils.log("Battery: Raw = " + value + " decoded: " + _batteryRemaining);
        WatchUi.requestUpdate();
    }

    private function processSafetyHeadroom( value ) {
        _safetyHeadroom = value.decodeNumber(Lang.NUMBER_FORMAT_UINT8, {});
        Utils.log("Safety Headroom: Raw = " + value + " decoded: " + _safetyHeadroom);
        WatchUi.requestUpdate();
    }

    private function processSpeedRpm( value ) {
        var speedRpm =
            value.decodeNumber(Lang.NUMBER_FORMAT_UINT16,
                               {:endianness => Lang.ENDIAN_BIG});
        _speedMph = speedRpm * .033;
        WatchUi.requestUpdate();
    }

    private function processOdometer( value ) {
        var odometerRotations =
            value.decodeNumber(Lang.NUMBER_FORMAT_UINT16,
                               {:endianness => Lang.ENDIAN_BIG});
        Utils.log("Odometer: Raw = " + value + " decoded: " +
                  odometerRotations);
        _odometer = odometerRotations * 11 * Math.PI / 63360;
        WatchUi.requestUpdate();
    }

    private function processLifetimeOdometer(value) {
        _lifetimeOdometer =
            value.decodeNumber(Lang.NUMBER_FORMAT_UINT16,
                               {:endianness => Lang.ENDIAN_BIG});
        WatchUi.requestUpdate();
    }
}