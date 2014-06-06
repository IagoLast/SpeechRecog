package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMain;

import android.app.SearchManager;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.os.StrictMode;
import android.provider.AlarmClock;
import android.provider.MediaStore;
import android.util.Log;

import java.util.Calendar;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail.VtMail;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtParrot;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtWeather.VtWeather;


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
            service.speak("loro");
            service.setCurrentVoicetivity(new VtParrot(service));
        } else if (speech.matches("correo")) {
            service.setCurrentVoicetivity(new VtMail(service));
            service.speak(service.getResources().getString(R.string.Speech_Introduction_Welcome_Mail_Manager), false);
            service.speak(service.getResources().getString(R.string.Speech_Introduction_General_Command_Help), false);
        } else if (speech.matches("tiempo")) {
            service.speak("¿que ciudad?");
            service.setCurrentVoicetivity(new VtWeather(service));
        } else if (speech.matches("encender Bluetooth|encender blutud|encender bluetooth|encender blutooth")) {
            BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            if (!mBluetoothAdapter.isEnabled()) {
                mBluetoothAdapter.enable();
            }
            service.speak("Encendido.");
        } else if (speech.matches("apagar Bluetooth|apagar blutud|apagar bluetooth|apagar blutooth")) {
            BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            if (mBluetoothAdapter.isEnabled()) {
                mBluetoothAdapter.disable();
            }
            service.speak("Apagado.");

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
