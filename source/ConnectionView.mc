using Toybox.WatchUi;
using Toybox.StringUtil as Util;

class ConnectionView extends WatchUi.View {
    private var _connectionManager;
    private var _viewController;

    function initialize(connectionManager, viewController) {
        View.initialize();
        _connectionManager = connectionManager;
        _viewController = viewController;
    }

    function onUpdate(dc) {
        var text = "";
        switch (_connectionManager.getState()) {
            case _connectionManager.STATE_DISCONNECTED:
                text = "Disconnected";
                break;
            case _connectionManager.STATE_SCANNING:
                text = "Scanning";
                break;
            case _connectionManager.STATE_PAIRING:
                text = "Connecting [I---]";
                break;
            case _connectionManager.STATE_SETUP_HANDSHAKE:
                text = "Connecting [II--]";
                break;
            case _connectionManager.STATE_SEND_HANDSHAKE_RESPONSE:
                text = "Connecting [III-]";
                break;
            case _connectionManager.STATE_SETUP_KEEP_ALIVE:
                text = "Connecting [IIII]";
                break;
            case _connectionManager.STATE_CONNECTED:
                _viewController.pushOnewheelView();
                break;
        }
        Utils.log(text);

        dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_WHITE );
        dc.clear();

        var center_x = dc.getWidth() / 2;
        var center_y = dc.getWidth() / 2;

        dc.drawText(center_x,
                    center_y,
                    Graphics.FONT_MEDIUM,
                    text,
                    Graphics.TEXT_JUSTIFY_CENTER |
                            Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
