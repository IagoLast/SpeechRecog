package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtWeather;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.StrictMode;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONObject;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

/**
 * Created by iagolast on 25/04/14.
 */

public class VtWeather implements Voicetivity {
    private SpeechRecognitionService service;

    public VtWeather(SpeechRecognitionService service) {
        this.service = service;
    }

    //TODO: REFACTOR THIS CRAP.
    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("salir")) {
            service.speak("Saliendo.");
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Main"));

        } else {
            HttpClient defaultHttpClient = new DefaultHttpClient();
            try {
                // Enable Network on Main Thread
                StrictMode.ThreadPolicy defaultPolicy = StrictMode.getThreadPolicy();
                StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
                StrictMode.setThreadPolicy(policy);

                //Get current location.
                LocationManager lm = (LocationManager) service.getSystemService(Context.LOCATION_SERVICE);
                Location location = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
                double longitude = location.getLongitude();
                double latitude = location.getLatitude();

                //Build url and run http request.
                String url = "http://api.openweathermap.org/data/2.5/weather?lat=" + latitude + "&lon=" + longitude + "&lang=sp&units=metric";
                HttpResponse response = defaultHttpClient.execute(new HttpGet(url));

                // Extract data from reponse.
                JSONObject jsonObject = new JSONObject(EntityUtils.toString(response.getEntity()));
                JSONArray weather = jsonObject.getJSONArray("weather");
                JSONObject main = jsonObject.getJSONObject("main");
                long temperature = main.getLong("temp");
                temperature = Math.round(temperature);
                jsonObject = weather.getJSONObject(0);
                String description = jsonObject.getString("description");

                service.speak(description + " con temperaturas de " + temperature + " grados.");
                StrictMode.setThreadPolicy(defaultPolicy);
            } catch (Exception e) {
                service.speak("No puedo saber que tiempo hace, saliendo.");
                service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Main"));
            }
        }
    }

    @Override
    public String getIconName() {
        return "ic_weather";
    }

    @Override
    public String getName() {
        return "Weather";
    }

    @Override
    public String getDesc() {
        return "Saber el tiempo en tu zona.";
    }
}
