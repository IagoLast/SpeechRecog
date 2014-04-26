package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt;

import android.app.Service;
import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.util.Pair;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Created by iagolast on 26/04/14.
 */
public class Forecast {
    private Service service;
    private HttpClient httpClient;

    public Forecast(Service service) {
        this.service = service;
        httpClient = new DefaultHttpClient();
    }


    public String getWeatherForecastFromLocationName(String name) {
        try {
            return getForecastByLocation(getLocationByName(name));
        } catch (Exception e) {
            return "Ni idea.";
        }
    }

    public String getWeatherForecastInUserLocation() {
        try {
            return getForecastByLocation(getCurrentLocation());
        } catch (Exception e) {
            return "Ni idea.";
        }
    }


    /**
     * Gets user location using network provider.
     *
     * @return Pair containing latitude and longitude.
     */
    private Pair<Double, Double> getCurrentLocation() {
        LocationManager lm = (LocationManager) service.getSystemService(Context.LOCATION_SERVICE);
        Location location = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
        return new Pair<Double, Double>(location.getLongitude(), location.getLongitude());
    }

    private Pair<Double, Double> getLocationByName(String name) throws Exception {
        String url = "http://maps.google.com/maps/api/geocode/json?sensor=false&address=" + name;
        HttpResponse response = httpClient.execute(new HttpGet(url));
        JSONObject jsonObject = new JSONObject(EntityUtils.toString(response.getEntity()));
        JSONArray results = jsonObject.getJSONArray("results");
        jsonObject = results.getJSONObject(0);
        jsonObject = jsonObject.getJSONObject("geometry");
        jsonObject = jsonObject.getJSONObject("location");
        return new Pair(jsonObject.getDouble("lat"), jsonObject.getDouble("lng"));
    }

    private String getForecastByLocation(Pair<Double, Double> location) throws Exception {
        //Build url and run http request.
        String url = "http://api.openweathermap.org/data/2.5/weather?lat=" + location.first + "&lon=" + location.second + "&lang=sp&units=metric";
        HttpResponse response = httpClient.execute(new HttpGet(url));

        // Extract data from reponse.
        JSONObject jsonObject = new JSONObject(EntityUtils.toString(response.getEntity()));
        JSONArray weather = jsonObject.getJSONArray("weather");
        JSONObject main = jsonObject.getJSONObject("main");
        long temperature = main.getLong("temp");
        temperature = Math.round(temperature);
        jsonObject = weather.getJSONObject(0);
        String description = jsonObject.getString("description");

        return description + " con temperaturas de " + temperature + " grados.";
    }
}
