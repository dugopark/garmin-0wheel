using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.WatchUi as WatchUi;

class OWDelegate extends Ble.BleDelegate {
    private var _onScanResults = null;
    private var _onConnectedStateChanged = [];
    private var _onCharacteristicRead = [];
    private var _onDescriptorWrite = [];
    private var _onCharacteristicChanged = [];
    private var _onCharacteristicWrite = [];

    function initialize() {
        BleDelegate.initialize();
    }

    // Called after a scan is initiated.
    // Params:
    //     scanResults: Toybox.BluetoothLowEnergy.Iterator, iterator of
    //         BluetoothLowEnergy.ScanResult objects.
    function onScanResults(scanResults) {
        if (_onScanResults) {
            _onScanResults.invoke(scanResults);
        }
    }

    // Called after pairing a device and the connection has been made.
    // Params:
    //     device: Toybox.BluetoothLowEnergy.Device representing the connected
    //         device.
    //     state: A number indicating the connection state as in
    //         Toybox.BluetoothLowEnergy.CONNECTION_STATE_*
    function onConnectedStateChanged(device, state) {
        for (var i = 0; i < _onConnectedStateChanged.size(); ++i) {
            _onConnectedStateChanged[i].invoke(device, state);
        }
    }

    function onCharacteristicRead(char, status, value) {
        for (var i = 0; i < _onCharacteristicRead.size(); ++i) {
            _onCharacteristicRead[i].invoke(char, status, value);
        }
    }

    function onDescriptorWrite(descriptor, status) {
        for (var i = 0; i < _onDescriptorWrite.size(); ++i) {
            _onDescriptorWrite[i].invoke(descriptor, status);
        }
    }

    function onCharacteristicChanged(char, value) {
        for (var i = 0; i < _onCharacteristicChanged.size(); ++i) {
            _onCharacteristicChanged[i].invoke(char, value);
        }
    }

    function onCharacteristicWrite(char, status) {
        for (var i = 0; i < _onCharacteristicWrite.size(); ++i) {
            _onCharacteristicWrite[i].invoke(char, status);
        }
    }

    function notifyOnScanResults(callback) {
        _onScanResults = callback;
    }

    function notifyOnConnectedStateChanged(callback) {
        _onConnectedStateChanged.add(callback);
    }

    function notifyOnCharacteristicRead(callback) {
        _onCharacteristicRead.add(callback);
    }

    function notifyOnDescriptorWrite(callback) {
        _onDescriptorWrite.add(callback);
    }

    function notifyOnCharacteristicChanged(callback) {
        _onCharacteristicChanged.add(callback);
    }

    function notifyOnCharacteristicWrite(callback) {
        _onCharacteristicWrite.add(callback);
    }
}
