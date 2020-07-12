using Toybox.WatchUi;

class DeviceDelegate extends WatchUi.BehaviorDelegate {
    private var _owDataModel;

    function initialize( owDataModel ) {
        BehaviorDelegate.initialize();
        _owDataModel = owDataModel;
    }

/*
    function onBack() {
        _deviceDataModel.unpair();
        WatchUi.popView( WatchUi.SLIDE_DOWN );
        return true;
    }
*/
}
