var map;
var logging;
var interval;

$.fn.plotPosition = function(latitude, longitude, centre) {
  var location = new google.maps.LatLng(latitude, longitude);
  var marker = new google.maps.Marker({
    position : location,
    map : map
  });
  if (centre) {
    map.setCenter(location);
  }
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
          $(this).plotPosition(latitude, longitude, true);
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

  if (typeof(geo_position_js_simulator) != "undefined") {
    geo_position_js_simulator.init([
      { coords: { latitude : 53.5000, longitude : -1.1000 }, duration : 5000 },
      { coords: { latitude : 53.5100, longitude : -1.1100 }, duration : 5000 },
      { coords: { latitude : 53.5200, longitude : -1.1200 }, duration : 5000 },
      { coords: { latitude : 53.5300, longitude : -1.1300 }, duration : 5000 },
      { coords: { latitude : 53.5400, longitude : -1.1400 }, duration : 5000 },
      { coords: { latitude : 53.5500, longitude : -1.1500 }, duration : 5000 },
      { coords: { latitude : 53.5600, longitude : -1.1600 }, duration : 5000 },
      { coords: { latitude : 53.5700, longitude : -1.1700 }, duration : 5000 },
      { coords: { latitude : 53.5800, longitude : -1.1800 }, duration : 5000 },
      { coords: { latitude : 53.5900, longitude : -1.1900 }, duration : 5000 }
    ]);
  }

  $(this).setupTimer();

  logging = $("input#log_position").attr("checked");
  $("input#log_position").click(function() {
    logging = $(this).attr("checked");
  });

  interval = $("select#log_interval option:selected").val() * 60 * 1000;
  $("select#log_interval").change(function() {
    interval = $(this).find("option:selected").val() * 60 * 1000;
  });

  map = new google.maps.Map(document.getElementById("map_canvas"), {
    zoom : 12,
    mapTypeId : google.maps.MapTypeId.ROADMAP
  });
  nodes = [];
  bounds = new google.maps.LatLngBounds;
  $("table#stops tbody tr").each(function() {
    name = $(this).find(".name").text();
    link = $(this).find(".name a");
    arrives_at = $(this).find(".arrives_at").text();
    departs_at = $(this).find(".departs_at").text();
    latitude = $(this).find(".latitude").text();
    longitude = $(this).find(".longitude").text();
    var location = new google.maps.LatLng(latitude, longitude);
    nodes.push(location);
    bounds.extend(location);
    link.click(function() {
      map.setCenter(location);
      return false;
    });
    paragraphs = [name]
    if (arrives_at.length > 0) {
      paragraphs.push("Arrives: " + arrives_at);
    }
    if (departs_at.length > 0) {
      paragraphs.push("Departs: " + departs_at);
    }
    description = $.map(paragraphs, function(paragraph) {
      return "<p>" + paragraph + "</p>";
    }).join("");
    var infoWindow = new google.maps.InfoWindow({
      content : description
    });
    var marker = new google.maps.Marker({
      position : location,
      map : map
    });
    google.maps.event.addListener(marker, 'click', function() {
      infoWindow.open(map, marker);
    });
  });
  var line = new google.maps.Polyline({
    path : nodes,
    map : map
  });
  map.fitBounds(bounds);
  $("table#positions tbody tr").each(function() {
    latitude = $(this).find(".latitude").text();
    longitude = $(this).find(".longitude").text();
    $(this).plotPosition(latitude, longitude, true);
  });
});
