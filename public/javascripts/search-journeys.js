$(document).ready(function () {

  if (typeof(geo_position_js_simulator) != "undefined") {
    geo_position_js_simulator.init([
      { coords: { latitude : 53.5228, longitude : -1.1398 }, duration : 5000 }
    ]);
  };

  latitude = $("input#latitude").attr("value");
  longitude = $("input#longitude").attr("value");
  if ((latitude == "") && (longitude == "")) {
    if (geo_position_js.init()) {
      geo_position_js.getCurrentPosition(
        function(data) {
          console.log("Found position using Geo-location API");
          $("input#latitude").attr("value", data.coords.latitude);
          $("input#longitude").attr("value", data.coords.longitude);
          $.get("/stations/nearby", { "latitude" : data.coords.latitude, "longitude" : data.coords.longitude }, function(data) {
            $("select#station_code option").remove();
            $.each(data, function(index, value) {
              $("select#station_code").append('<option value="' + value.station.code + '">' + value.station.name + ' (' + (Math.round(value.station.distance * 10) / 10) + ' miles)' + '</option>');
            });
          });
        },
        function(data) {
          console.log("Error using Geo-location API");
        },
        { enableHighAccuracy : true }
      );
    } else {
      console.log("Geo-location API not available");
    };
  };
});
