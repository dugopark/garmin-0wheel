using Toybox.System as Sys;
using Toybox.WatchUi as WatchUi;

class ViewController {
    private var _modelFactory;

    function initialize( modelFactory ) {
        _modelFactory = modelFactory;
    }

    function getInitialView(connectionManager) {
        return [new ConnectionView(connectionManager, self),
                new ConnectionDelegate(connectionManager)];
    }

    function pushOnewheelView() {
        var owDataModel = _modelFactory.getOWDataModel();
        WatchUi.pushView(new DeviceView(owDataModel),
                         new DeviceDelegate(owDataModel),
                         WatchUi.SLIDE_UP);
    }
}
