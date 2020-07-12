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
        Utils.log("onStart");
        try {
            _profileManager = new ProfileManager();
        } catch (e) {
            Utils.log("exception: " + e.getErrorMessage());
            Sys.exit();
        }
        Utils.log("_profileManager created");
        _bleDelegate = new OWDelegate();
        Utils.log("_bleDelegate created");
        _connectionManager = new ConnectionManager(_bleDelegate,
                                                   _profileManager);
        Utils.log("_connectionManager created");
        _modelFactory = new DataModelFactory(
                _bleDelegate, _profileManager, _connectionManager);
        Utils.log("_modelFactory created");
        _viewController = new ViewController( _modelFactory );
        Utils.log("_viewController created");
        Ble.setDelegate( _bleDelegate );
        Utils.log("setting bleDelegate");
        _profileManager.registerProfiles();
        Utils.log("registering profiles");
        Ble.setScanState( Ble.SCAN_STATE_SCANNING );
        Utils.log("starting scanning");
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
        return _viewController.getInitialView();
    }

}
