package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.speech.tts.TextToSpeech;
import android.speech.tts.TextToSpeech.OnInitListener;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService.SimpleBinder;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtParrot;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtWritter;

public class MainActivity extends Activity implements OnInitListener {

    private TextView textView;
    private Button recordButton;
    private Button listenButton;

    private TextToSpeech textToSpeech;
    private SpeechRecognitionService speechRecognitionService;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        loadUI();
        setListeners();
        bindSpeechRecognizer();
        textToSpeech = new TextToSpeech(this, this);
    }

    @Override
    public void onInit(int status) {

    }

    /**
     * Find each ui element and and assigns it to his local variable.
     */
    private void loadUI() {
        recordButton = (Button) findViewById(R.id.button);
        listenButton = (Button) findViewById(R.id.button2);
        textView = (TextView) findViewById(R.id.textView);
    }

    /**
     * Assigns listeners to buttons.
     */
    private void setListeners() {
        recordButton.setOnClickListener(onButtonParrotClick);
        listenButton.setOnClickListener(onButtonTwoClick);
    }

    /**
     * Binds a speech recognizer to this activity.
     */
    private void bindSpeechRecognizer() {
        bindService(SpeechRecognitionService.getServiceIntent(this),
                speechRecogniterConnection, Context.BIND_AUTO_CREATE);
    }

    /**
     *
     */
    OnClickListener onButtonParrotClick = new OnClickListener() {
        public void onClick(View v) {
            speechRecognitionService.setCurrentVoicetivity(new VtParrot(textToSpeech));
        }
    };

    /**
     * When clicked app reads text in the textView.
     */
    OnClickListener onButtonTwoClick = new OnClickListener() {
        public void onClick(View v) {
            speechRecognitionService.setCurrentVoicetivity(new VtWritter(textView));
        }
    };

    /**
     * Service connection que asigna una voicetivity y empieza a escuchar cuando se conecta.
     */
    private ServiceConnection speechRecogniterConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName arg0, IBinder bind) {
            SimpleBinder sBinder = (SimpleBinder) bind;
            speechRecognitionService = sBinder.getService();
            speechRecognitionService.startListening();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
        }
    };
}
