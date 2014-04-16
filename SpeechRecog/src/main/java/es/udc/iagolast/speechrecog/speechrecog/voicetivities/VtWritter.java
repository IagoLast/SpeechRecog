package es.udc.iagolast.speechrecog.speechrecog.voicetivities;

import android.widget.TextView;

/**
 * Created by iagolast on 11/04/14.
 */
public class VtWritter implements Voicetivity {
    private TextView textView;

    public VtWritter(TextView textView) {
        this.textView = textView;
    }

    @Override
    public void processSpeech(String speech) {
        textView.setText(speech);
    }
}