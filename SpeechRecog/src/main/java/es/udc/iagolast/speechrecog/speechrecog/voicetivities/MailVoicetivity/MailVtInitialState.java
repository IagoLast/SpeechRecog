package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.res.Resources;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;

public class MailVtInitialState implements MailVoicetivityState {

    private VtMail voicetivity;
    private Resources res;


    public MailVtInitialState(VtMail voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();

    }

    @Override
    public void processSpeech(String speech) {

        Log.d("INIT STATE", "IN");

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Check_Mail))) {

            if (voicetivity.mailClient.hasUnreadMail()) {
                voicetivity.speak(res.getString(R.string.Speech_Keyword_Unread_Mail), true);
                voicetivity.state = new MailVtStateOne(voicetivity);

            } else
                voicetivity.speak(res.getString(R.string.Speech_Response_Non_Unread_Mail), true);

        } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Write_Mail))) {
            //TODO
            voicetivity.speak("Función no implementada aún.", true);

        } else
            voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);


    }
}
