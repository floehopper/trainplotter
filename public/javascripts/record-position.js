var map;
var logging;
var interval;

$.fn.plotPosition = function(latitude, longitude) {
  var location = new google.maps.LatLng(latitude, longitude);
  var marker = new google.maps.Marker({
    position : location,
    map : map
  });
  map.setCenter(location);
}

$.fn.recordPosition = function() {
  if (!logging) {
    return;
  };
  if (geo_position_js.init()) {
    geo_position_js.getCurrentPosition(
      function(data) {
        var latitude = data.coords.latitude;
        var longitude = data.coords.longitude;
        console.log([latitude, longitude].join(","));
        url = window.location.href + "/positions"
        $.post(url, { "latitude" : latitude, "longitude" : longitude }, function(data) {
          $("table#positions tbody tr").last().after(data);
          $(this).plotPosition(latitude, longitude);
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
}

$.fn.setupTimer = function() {
  timeout = setTimeout(function() {
    $(this).recordPosition();
    $(this).setupTimer();
  }, interval);
}

$(document).ready(function () {

  // stubs out geo-location for testing
  // geo_position_js_simulator.init([
  //   { coords: { latitude : 53.5000, longitude : -1.1000 }, duration : 5000 },
  //   { coords: { latitude : 53.5100, longitude : -1.1100 }, duration : 5000 },
  //   { coords: { latitude : 53.5200, longitude : -1.1200 }, duration : 5000 },
  //   { coords: { latitude : 53.5300, longitude : -1.1300 }, duration : 5000 },
  //   { coords: { latitude : 53.5400, longitude : -1.1400 }, duration : 5000 },
  //   { coords: { latitude : 53.5500, longitude : -1.1500 }, duration : 5000 },
  //   { coords: { latitude : 53.5600, longitude : -1.1600 }, duration : 5000 },
  //   { coords: { latitude : 53.5700, longitude : -1.1700 }, duration : 5000 },
  //   { coords: { latitude : 53.5800, longitude : -1.1800 }, duration : 5000 },
  //   { coords: { latitude : 53.5900, longitude : -1.1900 }, duration : 5000 }
  // ]);

  $(this).setupTimer();

  logging = $("input#log_position").attr("checked");
  $("input#log_position").click(function() {
    logging = $(this).attr("checked");
  });
  
  interval = $("select#log_interval option:selected").val() * 1000;
  $("select#log_interval").change(function() {
    interval = $(this).find("option:selected").val() * 1000;
  });

  map = new google.maps.Map(document.getElementById("map_canvas"), {
    zoom : 12,
    mapTypeId : google.maps.MapTypeId.ROADMAP
  });
  $("table#positions tbody tr").each(function() {
    latitude = $(this).find(".latitude").text();
    longitude = $(this).find(".longitude").text();
    $(this).plotPosition(latitude, longitude);
  });
});
