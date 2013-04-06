// JavaScript helper code for realtime API
// Defines "startRealtime" function to start up

function initializeModel(model) {
  function makeTrack(id, instrument) {
    return model.createMap({
       'id': id,
       'instrument': instrument,
       'grid': model.createMap(),
    });
  }
  var tracks = model.createList([
    makeTrack(0, 'percussion'),
    makeTrack(1, 'piano')
  ]);
  model.getRoot().set('tracks', tracks);
}

var options = {
  /**
   * Client ID from the APIs Console.
   */
  clientId: '394528946805.apps.googleusercontent.com',

  /**
   * The ID of the button to click to authorize. Must be a DOM element ID.
   */
  authButtonElementId: 'authorizeButton',

  /**
   * Function to be called when a Realtime model is first created.
   */
  initializeModel: initializeModel,

  /**
   * Autocreate files right after auth automatically.
   */
  autoCreate: true,

  /**
   * Autocreate files right after auth automatically.
   */
   defaultTitle: "Dart Liftoff: Audio3 Demo",
};

function startRealtime(onFileLoaded) {
 
      options.onFileLoaded = function(doc) {
        var root = doc.getModel().getRoot();  
        onFileLoaded(root);
      };
      
      var realtimeLoader = new rtclient.RealtimeLoader(options);
      realtimeLoader.start();
}

function setGridValue(grid, key, value) {
  grid.set(key, value);
}
