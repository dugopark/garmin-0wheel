using Toybox.WatchUi;

class ConnectionDelegate extends WatchUi.BehaviorDelegate {
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
