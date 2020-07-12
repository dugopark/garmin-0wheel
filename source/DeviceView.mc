using Toybox.WatchUi;
using Toybox.StringUtil as Util;

class DeviceView extends WatchUi.View {
    private var _dataModel;

    function initialize( dataModel ) {
        View.initialize();

        _dataModel = dataModel;
    }

    function onUpdate(dc) {
        var center_x = dc.getWidth() / 2;
        var center_y = dc.getWidth() / 2;

        if (!_dataModel.isConnected()) {
            dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_WHITE );
            dc.clear();

            dc.drawText(center_x,
                        center_y,
                        Graphics.FONT_MEDIUM,
                        "Connecting",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_WHITE );
            dc.clear();

            // Draw battery ring
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_WHITE);
            dc.setPenWidth(20);
            var batteryRemaining = _dataModel.getBatteryRemaining();
            var degrees = (3.6 * batteryRemaining).toLong();
            var endDegrees = (degrees + 90) % 360;
            dc.drawArc(center_x, center_y, center_x,
                       Graphics.ARC_COUNTER_CLOCKWISE,
                       90, endDegrees);

            // Draw battery percent text
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            var batteryPercentString = batteryRemaining.format("%3d") + "%";
            dc.drawText(center_x, 20, Graphics.FONT_SMALL, batteryPercentString,
                        Graphics.TEXT_JUSTIFY_CENTER);

            var speed = _dataModel.getSpeedMph();
            var speedString = speed.format("%2.1f");
            dc.drawText(
                center_x, center_y, Graphics.FONT_NUMBER_HOT, speedString,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Draw trip odometer
            var odometer = _dataModel.getOdometer();
            var odometerString = odometer.format("%2.1f");
            var yOffset =
                   center_y + dc.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2;
            var xOffset = center_x + 30;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_WHITE);
            dc.drawText(xOffset, yOffset, Graphics.FONT_TINY,
                        "Trip (Miles)", Graphics.TEXT_JUSTIFY_RIGHT);

            yOffset = center_y + dc.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2;
            xOffset = center_x + 35;
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            dc.drawText(xOffset, yOffset, Graphics.FONT_TINY,
                        odometerString, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function drawBatteryPercent(dc, batteryRemaining) {
    }
}
