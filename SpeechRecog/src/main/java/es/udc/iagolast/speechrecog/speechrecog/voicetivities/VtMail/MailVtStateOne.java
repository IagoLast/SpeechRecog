package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail;


import android.content.res.Resources;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;

public class MailVtStateOne implements MailVoicetivityState {

    private VtMail voicetivity;
    private Resources res;


    public MailVtStateOne(VtMail voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();
    }


    @Override
    public void processSpeech(String speech) {

        Log.d("STATE 1", "IN");

        if (speech.matches(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.state = new MailVtStateTwo(voicetivity);


        } else if (speech.matches(res.getString(R.string.Speech_Keyword_No))) {
            voicetivity.state = new MailVtInitialState(voicetivity);

        } else
            voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);

    }

    @Override
    public void onHelpRequest() {
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_CheckMail_Afirmative), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_CheckMail_Negative), false);

    }
}
