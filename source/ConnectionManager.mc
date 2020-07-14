// Manages the connection to the Onewheel.
//
// Takes care of the initial scan, handshake, and periodic keep alive pings.
//
// The handshake protocol is a multi-step process that runs as follows.
// Credit to pOnewheel author Kevin Watkins for figuring this out.
//
// 1. Request the firmware revision characteristic from the OW service.
// 2. If firmware revision is < 4034, no extra steps needed.
//    If firmware revision >= 4034 (Gemini and newer), turn on notifications
//    for UART_SERIAL_READ_CHARACTERISTIC.
// 3. When notification request has been accepted, write the firmware revision
//    number back onto itself to kick off the authentication process.
//    This kicks off something in the Onewheel which starts writing bytes to the
//    UART_SERIAL_READ_CHARACTERISTIC.
// 4. As bytes come in, keep appending them to a buffer until the number of
//    collected bytes >= 20.
// 5. Once collected bytes >= 20, calculate the challenge response.
//    5.1. Write 3 bytes to the start of the challenge response: "435258"
//    5.2. Prep a secondary buffer, and copy bytes [3, 19) from the collected
//         buffer of bytes from step 4.
//    5.3. Append "D9255F0F23354E19BA739CCDC4A91765" to the secondary buffer.
//    5.4. Calculate the MD5 digest for the secondary buffer, and append that
//         to the challenge response..
//    5.5. Calculate the checksum across the entire challenge response, and
//         append that to the end of the challenge response.
// 6. Write the challenge response to UART_SERIAL_WRITE_CHARACTERISTIC.
// 7. If the write was unsuccessful, abort and try again the next time the OW
//    writes to UART_SERIAL_READ_CHARACTERISTIC.
//    If the write was successful, turn off notifications for the
//    UART_SERIAL_READ_CHARACTERISTIC, since we're done with it.
// 8. Once notification disable request is accepted, start the periodic keep
//    alive, which consists of writing the fimrware revision characteristic
//    back onto itself. Also, notify any listeners that connection is completed.

using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Cryptography as Cryptography;
using Toybox.System as Sys;
using Toybox.Timer;

class ConnectionManager {
    // Connection status.
    enum {
        STATE_DISCONNECTED,
        STATE_SCANNING,
        STATE_PAIRING,
        STATE_SETUP_HANDSHAKE,
        STATE_SEND_HANDSHAKE_RESPONSE,
        STATE_SETUP_KEEP_ALIVE,
        STATE_CONNECTED,
    }

    private var OW_DEVICE_PREFIX = "ow";

    private var _profileManager;
    private var _scanResult;
    private var _device;
    private var _handshakeChallenge;
    private var _handshakeChallengeIndex;
    private var _pairTimer;
    private var _uartReadTimer;
    private var _keepAliveTimer;
    private var _service;
    private var _state;

    private var _firmwareRevision;
    private var _firmwareRevisionBytes;

    private var _onConnected;

    function initialize(bleDelegate, profileManager) {
        _profileManager = profileManager;
        _device = null;
        _handshakeChallengeIndex = 0;
        _handshakeChallenge = new [20]b;
        _uartReadTimer = new Timer.Timer();
        _keepAliveTimer = new Timer.Timer();
        _pairTimer = new Timer.Timer();
        _service = null;
        _state = ConnectionManager.STATE_DISCONNECTED;

        _firmwareRevision = 0;
        _firmwareRevisionBytes = []b;

        _onConnected = null;

        // Register handlers to be called for BLE events
        bleDelegate.notifyOnScanResults(method(:onScanResults));
        bleDelegate.notifyOnConnectedStateChanged(
                method(:onConnectedStateChanged));
        bleDelegate.notifyOnCharacteristicRead(method(:onCharacteristicRead));
        bleDelegate.notifyOnDescriptorWrite(method(:onDescriptorWrite));
        bleDelegate.notifyOnCharacteristicChanged(
                method(:onCharacteristicChanged));
        bleDelegate.notifyOnCharacteristicWrite(
                method(:onCharacteristicWrite));

        startScanning();
    }

    function notifyConnected(callback) {
        _onConnected = callback;
    }

    function startScanning() {
        _state = STATE_SCANNING;
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }

    function onScanResults(scanResults) {
        for (var result = scanResults.next(); result != null;
                result = scanResults.next()) {
            var deviceName = result.getDeviceName();
            if (deviceName != null &&
                (deviceName.find(OW_DEVICE_PREFIX) == 0 ||
                 deviceName.find("Onewheel") == 0)) {
                Utils.log("Found Onewheel device: " + deviceName);
                _state = STATE_PAIRING;
                _scanResult = result;
                Ble.setScanState(Ble.SCAN_STATE_OFF);
                pair();
                break;
            }
        }
    }

    function resetConnection() {
        unpair();
        _scanResult = null;
        _device = null;
        _handshakeChallengeIndex = 0;
        _state = STATE_DISCONNECTED;
        startScanning();
    }

    private function pair() {
        Utils.log("Sending pair request.");
        try {
            _device = Ble.pairDevice(_scanResult);
        } catch (ex) {
            Utils.log("Error retrying pairing: " + ex.getErrorMessage());
        }
        // Sometimes pairing hangs and nothing happens. Pairing takes
        // ridiculously long, 30s - 45s so try pairing again in case it hasn't
        // completed by 50 seconds.
        _pairTimer.start(method(:retryPair), 50000, false);
    }

    function retryPair() {
        if (_state == STATE_PAIRING) {
            Utils.log("Pairing request timed out, pairing again.");
            pair();
        }
    }

    function unpair() {
        if (_device != null) {
            Ble.unpairDevice(_device);
        }
    }

    function onConnectedStateChanged(device, state) {
        if (state == Ble.CONNECTION_STATE_CONNECTED) {
            if (device != _device) {
                Utils.log("Device that is connecting doesn't match our device.");
                return;
            }
            _service = device.getService(_profileManager.ONEWHEEL_SERVICE);
            if (_service == null) {
                // TODO: Sometimes we end up here.
                Utils.log("Couldn't find Onewheel BLE service. Resetting " +
                          "connection, and starting over.");
                resetConnection();
                return;
            }
            Utils.log("OW device initial pairing successful.");
            _state = STATE_SETUP_HANDSHAKE;
            startHandshake();
        } else {
            // The device disconnected, restart the connection.
            Utils.log(
                    "ConnectionManager: Onewheel disconnected, reconnecting.");
            resetConnection();
            return;
        }
    }

    private function startHandshake() {
        _state = ConnectionManager.STATE_SETUP_HANDSHAKE;
        // Step 1
        Utils.log("Starting handshake protocol.");
        var characteristic = _service.getCharacteristic(
                _profileManager.FIRMWARE_REVISION_CHARACTERISTIC);
        if (characteristic == null) {
            Utils.log("Couldn't find firmware revision characteristic.");
            _state = STATE_DISCONNECTED;
            return;
        }

        Utils.log(
                "Step 1: Requesting read of firmware revision characteristic.");
        characteristic.requestRead();
    }

    function onCharacteristicRead(characteristic, status, value) {
        if (_state != ConnectionManager.STATE_SETUP_HANDSHAKE) {
            return;
        }
        Utils.log("ConnectionManager: onCharacteristicRead for uuid: " + characteristic.getUuid());
        if (status != Ble.STATUS_SUCCESS ||
            !characteristic.getUuid().equals(
                _profileManager.FIRMWARE_REVISION_CHARACTERISTIC)) {
            Utils.log("Failed to read characteristic with uuid: " +
                    characteristic.getUuid());
            _state = ConnectionManager.STATE_DISCONNECTED;
            return;
        }

        // Step 2
        processFirmwareRevision(value);
        if (_firmwareRevision >= 4034) {
            Utils.log("Step 2: Gemini or newer. Requesting notifications " +
                        "for UART_SERIAL_READ_CHARACTERISTIC");
            var serialReadChar = _service.getCharacteristic(
                    _profileManager.UART_SERIAL_READ_CHARACTERISTIC);
            requestNotification(serialReadChar);
        } else {
            Utils.log("Older than gemini. No handshake needed.");
            _state = STATE_CONNECTED;
            _onConnected.invoke(_device);
        }
    }

    private function requestNotification(char) {
        var cccd = char.getDescriptor(Ble.cccdUuid());
        cccd.requestWrite([0x01, 0x00]b);
    }

    private function processFirmwareRevision(value) {
        _firmwareRevisionBytes = value;
        _firmwareRevision =
            value.decodeNumber(Lang.NUMBER_FORMAT_UINT16,
                               {:endianness => Lang.ENDIAN_BIG});
        Utils.log("Firmware revision: " + _firmwareRevision);
    }

    function onDescriptorWrite(descriptor, status) {
        switch (_state) {
            case STATE_SETUP_HANDSHAKE:
                Utils.log("ConnectionManager: onDescriptorWrite, STATE_SETUP_HANDSHAKE");
                if (status != Ble.STATUS_SUCCESS ||
                    !descriptor.getCharacteristic().getUuid().equals(
                            _profileManager.UART_SERIAL_READ_CHARACTERISTIC)) {
                    Utils.log("Unexpected descriptor write during "  +
                                "handshake.");
                    _state = ConnectionManager.STATE_DISCONNECTED;
                }
                Utils.log("Step 3: Notifications enabled for " +
                            "UART_SERIAL_READ_CHARACTERISTIC. Sending " +
                            "handshake init.");
                sendHandshakeInit();
                return;
            case STATE_SETUP_KEEP_ALIVE:
                Utils.log("ConnectionManager: onDescriptorWrite, STATE_SETUP_KEEP_ALIVE");
                if (!descriptor.getCharacteristic().getUuid().equals(
                        _profileManager.UART_SERIAL_READ_CHARACTERISTIC)) {
                    Utils.log("Got descriptor write notification for the wrong characteristic. " +
                              "Not starting keepalive timer.");
                    return;
                }
                Utils.log("Starting keep alive timer.");
                _state = STATE_CONNECTED;
                _keepAliveTimer.start(method(:sendHandshakeInit), 15000, true);
                _onConnected.invoke(_device);
                return;
        }
    }

    function sendHandshakeInit() {
        var characteristic = _service.getCharacteristic(
                _profileManager.FIRMWARE_REVISION_CHARACTERISTIC);
        if (characteristic == null) {
            Utils.log("Failed to find firmware revision characteristic.");
            _state = ConnectionManager.STATE_DISCONNECTED;
            return;
        }
        // Write and don't bother to get a response, since this is used only as
        // a signal to the OW to kick off the handshake process.
        if (_state == STATE_SETUP_HANDSHAKE) {
            Utils.log("Sending handshake init");
        } else if (_state == STATE_CONNECTED) {
            Utils.log("Sending keepalive");
        }
        try {
            characteristic.requestWrite(
                    _firmwareRevisionBytes,
                    { :writeType => Ble.WRITE_TYPE_DEFAULT });
        } catch (ex) {
            if (_state == STATE_CONNECTED) {
                Utils.log("Last keep alive still in progress, skipping: " +
                          ex.getErrorMessage());
            }
        }
    }

    function restartSerialRead() {
        Utils.log("ConnectionManager: " +
                  "Timed out while waiting for UART_SERIAL_READ. Sending " +
                  "handshake init again.");
        _handshakeChallengeIndex = 0;
        sendHandshakeInit();
    }

    function onCharacteristicChanged(characteristic, value) {
        if (_state != ConnectionManager.STATE_SETUP_HANDSHAKE) {
            return;
        }
        if (!characteristic.getUuid().equals(
                _profileManager.UART_SERIAL_READ_CHARACTERISTIC)) {
            Utils.log("Unexpected chacteristic read during handshake.");
            _state = ConnectionManager.STATE_DISCONNECTED;
            return;
        }
        // Step 4
        _uartReadTimer.stop();
        appendToHandshakeChallenge(value);

        if (_handshakeChallengeIndex < 20 ||
            _state != STATE_SETUP_HANDSHAKE) {
            Utils.log("Step 4.1: _handshakeChallengeIndex = " + _handshakeChallengeIndex +
                      " _state = " + _state);

            // Wait 5 seconds for the next SERIAL_READ. If not, reset and start
            // all over. Sometimes the BLE interface hangs while reading from
            // UART_SERIAL_READ_CHARACTERISTIC.
            _uartReadTimer.start(method(:restartSerialRead), 5000, false);
            return;
        }
        processHandshake();
    }

    private function appendToHandshakeChallenge(value) {
        for (var i = 0; i < value.size(); ++i) {
            _handshakeChallenge[_handshakeChallengeIndex] = value[i];
            ++_handshakeChallengeIndex;
        }
    }

    function processHandshake() {
        Utils.log("Step 4.1: _handshakeChallengeIndex = " + _handshakeChallengeIndex +
                  " _state = " + _state + " challenge: " + _handshakeChallenge);

        _state = STATE_SEND_HANDSHAKE_RESPONSE;
        // Step 5
        Utils.log("Step 5: Calculating handshake response.");

        // Step 5.1
        // Write the bytes "435258"
        var out = [67, 82, 88]b;
        Utils.log("out: " + out);

        // Step 5.2
        var md5Input = _handshakeChallenge.slice(3, 19);
        // Step 5.3
        // Write the bytes "D9255F0F23354E19BA739CCDC4A91765"
        md5Input.addAll([217, 37, 95, 15, 35, 53, 78, 25, 186, 115, 156, 205,
                         196, 169, 23, 101]b);

        // Step 5.4
        var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_MD5});
        hash.update(md5Input);
        out.addAll(hash.digest());

        // Step 5.5
        var checkByte = 0;
        for (var i = 0; i < out.size(); ++i) {
            checkByte = checkByte ^ out[i];
        }
        out.add(checkByte);

        // Step 6
        Utils.log("Step 6: Writing handshake response to UART_SERIAL_WRITE.");
        var characteristic = _service.getCharacteristic(
                _profileManager.UART_SERIAL_WRITE_CHARACTERISTIC);
        if (characteristic == null) {
            Utils.log("Couldn't find characteristic " +
                        "UART_SERIAL_WRITE_CHARACTERISTIC");
            _state = ConnectionManager.STATE_DISCONNECTED;
            return;
        }
        characteristic.requestWrite(
                out,
                { :writeType => Ble.WRITE_TYPE_WITH_RESPONSE });
    }

    function onCharacteristicWrite(char, status) {
        if (_state != ConnectionManager.STATE_SEND_HANDSHAKE_RESPONSE) {
            return;
        }
        if (char.getUuid().equals(_profileManager.FIRMWARE_REVISION_CHARACTERISTIC)) {
            Utils.log("Weird, got a callback for writing the handshake init.");
            return;
        }
        if (status != Ble.STATUS_SUCCESS ||
            !char.getUuid().equals(
                    _profileManager.UART_SERIAL_WRITE_CHARACTERISTIC)) {
            Utils.log("Handshake response write to UART_SERIAL_WRITE " +
                        "failed with status: " + status);
            return;
        }
        Utils.log("Step 6: Handshake response written.");

        // Step 7
        _state = ConnectionManager.STATE_SETUP_KEEP_ALIVE;
        disableNotification(_profileManager.UART_SERIAL_READ_CHARACTERISTIC);
    }

    private function disableNotification(uuid) {
        Utils.log("Disabling notifications for UART_SERIAL_READ with uuid: " + uuid);
        var characteristic = _service.getCharacteristic(uuid);
        var cccd = characteristic.getDescriptor(Ble.cccdUuid());
        cccd.requestWrite([0x00, 0x00]b);
    }
}