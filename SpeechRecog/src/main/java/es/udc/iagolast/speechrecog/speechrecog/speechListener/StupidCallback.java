package es.udc.iagolast.speechrecog.speechrecog.speechListener;

import android.widget.TextView;

/**
 * Created by iagolast on 16/03/14.
 * This callback only writes speech in a given textView.
 *
 */
public class StupidCallback implements SpeechCallback{
    private TextView textView;

    public StupidCallback(TextView textView){
        this.textView = textView;

    }

    @Override
    public void processSpeech(String speech) {
        textView.setText(speech);
    }
}
