// app/js/index.js - Client-side JavaScript for Rice Blast Forecast App

/**
 * Geolocation function
 * Gets user's current position and sends it to Shiny
 */
export function geolocate() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            function (position) {
                Shiny.setInputValue('app-geolocation_lat', position.coords.latitude, { priority: 'event' });
                Shiny.setInputValue('app-geolocation_long', position.coords.longitude, { priority: 'event' });
            },
            function (error) {
                alert('Geolocation error: ' + error.message);
            }
        );
    } else {
        alert('Geolocation is not supported by this browser.');
    }
}

// Make geolocate available globally for use with shinyjs::runjs()
window.app = window.app || {};
window.app.geolocate = geolocate;
