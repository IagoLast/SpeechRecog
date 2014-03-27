package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.speech.tts.TextToSpeech.OnInitListener;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;

public class MainActivity extends Activity implements OnInitListener {

    private TextView textView;
    private Button recordButton;
    private Button listenButton;
    private TextToSpeech textToSpeech;
    private Intent speechService;

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
        recordButton.setOnClickListener(onRecordClick);
        listenButton.setOnClickListener(onListenClick);
    }

    /**
     *  Creates a speech recognizer with a callback, the callback will write
     *  the speech in the textView.
     */
    private void createSpeechRecognizer() {
        speechService = new Intent(this, SpeechRecognitionService.class);
        startService(speechService);

        textToSpeech = new TextToSpeech(this, this);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        loadUI();
        setListeners();
        createSpeechRecognizer();
    }

    @Override
    public void onInit(int status) {

    }


    /**
     * When clicked app starts to listen.
     */
    OnClickListener onRecordClick = new OnClickListener() {
        public void onClick(View v) {
        }
    };

    /**
     * When clicked app speaks.
     */
    OnClickListener onListenClick = new OnClickListener() {
        public void onClick(View v) {
            textToSpeech.speak(textView.getText().toString(), TextToSpeech.QUEUE_FLUSH, null);
        }
    };

}
