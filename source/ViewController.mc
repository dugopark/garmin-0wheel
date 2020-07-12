using Toybox.System as Sys;
using Toybox.WatchUi as WatchUi;

class ViewController {
    private var _modelFactory;

    function initialize( modelFactory ) {
        _modelFactory = modelFactory;
    }

    function getInitialView() {
        var owDataModel = _modelFactory.getOWDataModel();
        return [new DeviceView(owDataModel),
                new DeviceDelegate(owDataModel)];
    }
}
