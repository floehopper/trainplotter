$(document).ready(function () {

  // stubs out geo-location for testing
  // geo_position_js_simulator.init([
  //   { coords: { latitude : 53.5228, longitude : -1.1398 }, duration : 5000 }
  // ]);

  if (geo_position_js.init()) {
    geo_position_js.getCurrentPosition(
      function(data) {
        if (($("#latitude").attr("value") == "") && ($("#latitude").attr("value") == "")) {
          path = "/departures/soon"
          url = path + "?latitude=" + data.coords.latitude + "&longitude=" + data.coords.longitude
          window.location.href = url;
        }
      },
      function(data) {
        alert("Error using Geo-location API");
      },
      { enableHighAccuracy : true }
    );
  } else {
    alert("Geo-location API not available");
  };
});
