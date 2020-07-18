using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;

class OnewheelApp extends Application.AppBase {
    private var _bleDelegate;
    private var _connectionManager;
    private var _profileManager;
    private var _modelFactory;
    private var _viewController;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        Utils.log("----- onStart ------");
        try {
            _profileManager = new ProfileManager();
        } catch (e) {
            Utils.log("exception: " + e.getErrorMessage());
            Sys.exit();
        }
        _bleDelegate = new OWDelegate();
        _connectionManager = new ConnectionManager(_bleDelegate,
                                                   _profileManager);
        _modelFactory = new DataModelFactory(
                _bleDelegate, _profileManager, _connectionManager);
        _modelFactory.getOWDataModel();
        _viewController = new ViewController( _modelFactory );
        Ble.setDelegate( _bleDelegate );
        for (var i = 0; i < 3; ++i) {
            try {
                var o = _profileManager.registerProfiles();
            } catch (ex) {
                Utils.log("Failed to register BLE profiles: " +
                          ex.getErrorMessage());
            }
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        _connectionManager.unpair();

        _viewController = null;
        _modelFactory = null;
        _connectionManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    // Returns the initial view.
    // Returns:
    //   An Array containing just a WatchUi.View and an optional
    //   WatchUi.InputDelegate
    function getInitialView() {
        return _viewController.getInitialView(_connectionManager);
    }

}
