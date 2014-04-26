package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtWeather;

import android.os.StrictMode;

import org.apache.http.client.HttpClient;
import org.apache.http.impl.client.DefaultHttpClient;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt.Forecast;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

/**
 * Created by iagolast on 25/04/14.
 */

public class VtWeather implements Voicetivity {
    private SpeechRecognitionService service;
    private HttpClient httpClient;

    public VtWeather(SpeechRecognitionService service) {
        this.service = service;
        httpClient = new DefaultHttpClient();
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("salir")) {
            service.speak("Saliendo.");
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Main"));
        } else {

            try {
                // Enable Network on Main Thread
                StrictMode.ThreadPolicy defaultPolicy = StrictMode.getThreadPolicy();
                StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
                StrictMode.setThreadPolicy(policy);
                Forecast forecast = new Forecast(service);
                service.speak(forecast.getWeatherForecastFromLocationName(speech));
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
