using Toybox.System as Sys;
using Toybox.WatchUi as WatchUi;

class DataModelFactory {
    // Dependancies
    private var _bleDelegate;
    private var _profileManager;
    private var _connectionManager;

    // Model Storage
    private var _owDataModel;

    function initialize(bleDelegate, profileManager, connectionManager) {
        _bleDelegate = bleDelegate;
        _profileManager = profileManager;
        _connectionManager = connectionManager;
    }

    function getOWDataModel() {
        var dataModel;
        if (null == _owDataModel || !_owDataModel.stillAlive()) {
            dataModel = new OWDataModel(_bleDelegate,
                                        _profileManager,
                                        _connectionManager);
            _owDataModel = dataModel.weak();
        } else {
            dataModel = _owDataModel.get();
        }
        return dataModel;
    }
}
