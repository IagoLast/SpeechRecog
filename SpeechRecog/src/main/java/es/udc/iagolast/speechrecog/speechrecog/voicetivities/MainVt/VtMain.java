package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt;

import android.app.SearchManager;
import android.content.Intent;
import android.os.StrictMode;
import android.provider.AlarmClock;
import android.provider.MediaStore;
import android.util.Log;

import java.util.Calendar;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

/**
 * Created by iagolast on 18/04/14.
 */
public class VtMain implements Voicetivity {
    protected SpeechRecognitionService service;

    public VtMain(SpeechRecognitionService service) {
        this.service = service;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("sacar foto")) {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        } else if (speech.equalsIgnoreCase("grabar vídeo")) {
            Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        } else if (speech.matches("buscar .*") || speech.matches("busca .*")) {
            String query = speech.substring(speech.indexOf(" "));
            Log.d("Buscando:", query);
            Intent intent = new Intent(Intent.ACTION_WEB_SEARCH);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.putExtra(SearchManager.QUERY, query);
            service.startActivity(intent);
        } else if (speech.matches("avísame en .* minutos")) {
            String minutesString = speech.substring(speech.indexOf("en ") + 3, speech.indexOf("minutos") - 1);
            Log.d("Recordatorio:", minutesString);
            int minutes = Integer.valueOf(minutesString);
            Intent intent = new Intent(AlarmClock.ACTION_SET_ALARM)
                    .putExtra(AlarmClock.EXTRA_MESSAGE, "Aviso")
                    .putExtra(AlarmClock.EXTRA_HOUR, Calendar.getInstance().getTime().getHours())
                    .putExtra(AlarmClock.EXTRA_MINUTES, Calendar.getInstance().getTime().getMinutes() + minutes);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);

        } else if (speech.matches("activar loro")) {
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Parrot"));
        } else if (speech.matches("correo")) {
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Mail"));
        } else if (speech.matches("tiempo")) {
            service.speak("¿que ciudad?");
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Weather"));
        } else if (speech.matches("qué tiempo hace") || speech.matches("dime qué tiempo hace")) {
            try {
                // Enable Network on Main Thread
                StrictMode.ThreadPolicy defaultPolicy = StrictMode.getThreadPolicy();
                StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
                StrictMode.setThreadPolicy(policy);
                Forecast forecast = new Forecast(service);
                service.speak(forecast.getWeatherForecastInUserLocation());
                StrictMode.setThreadPolicy(defaultPolicy);
            } catch (Exception e) {
                service.speak("No se..");
            }
        }
    }

    @Override
    public String getIconName() {
        return "ic_launcher";
    }

    @Override
    public String getName() {
        return "Main";
    }

    @Override
    public String getDesc() {
        return "The app´s core, includes basic commands.";
    }
}
