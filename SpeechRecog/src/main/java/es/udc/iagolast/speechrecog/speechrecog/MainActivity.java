package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.speech.tts.TextToSpeech.OnInitListener;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;

import java.util.List;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService.SimpleBinder;
import es.udc.iagolast.speechrecog.speechrecog.adapters.VtAdapter;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

public class MainActivity extends Activity implements OnInitListener {
    private SpeechRecognitionService speechRecognitionService;

    private ListView listView;
    private List<Voicetivity> voicetivityList;
    private VtAdapter vtAdapter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        startService(SpeechRecognitionService.getServiceIntent(this));
        bindSpeechRecognizer();
        loadUI();
        setListeners();
    }

    @Override
    public void onInit(int status) {

    }

    /**
     * Find each ui element and and assigns it to his local variable.
     */
    private void loadUI() {
        listView = (ListView) findViewById(R.id.listView);
    }

    /**
     * Popuates de listView with the new Voicetivity List.
     */
    private void populateListView(List<Voicetivity> voicetivityList) {
        vtAdapter = new VtAdapter(this, voicetivityList);
        listView.setAdapter(vtAdapter);
    }

    /**
     * Assigns listeners to buttons.
     */
    private void setListeners() {
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                if (view.getAlpha() == 0.2f) {
                    view.setAlpha(1.0f);
                } else {
                    view.setAlpha(0.2f);
                }
            }
        });
    }

    /**
     * Binds a speech recognizer to this activity.
     */
    private void bindSpeechRecognizer() {
        bindService(SpeechRecognitionService.getServiceIntent(this),
                speechRecogniterConnection, Context.BIND_AUTO_CREATE);
    }

    /**
     * Service connection que asigna una voicetivity y empieza a escuchar cuando se conecta.
     */
    private ServiceConnection speechRecogniterConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName arg0, IBinder bind) {
            SimpleBinder sBinder = (SimpleBinder) bind;
            speechRecognitionService = sBinder.getService();
            voicetivityList = VoicetivityManager.getInstance(speechRecognitionService).getVoicetivityList();
            populateListView(voicetivityList);
            speechRecognitionService.setCurrentVoicetivity(VoicetivityManager.getInstance(speechRecognitionService).getVoicetivity("Main"));
            speechRecognitionService.startListening();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
        }
    };
}
