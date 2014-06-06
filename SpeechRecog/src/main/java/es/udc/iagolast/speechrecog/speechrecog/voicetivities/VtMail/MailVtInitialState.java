package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail;


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

        if (speech.matches(res.getString(R.string.Speech_Keyword_Check_Mail))) {

            if (voicetivity.mailClient.hasUnreadMail()) {
                voicetivity.speak(res.getString(R.string.Speech_Response_Unread_Mail), true);
                voicetivity.state = new MailVtStateOne(voicetivity);

            } else
                voicetivity.speak(res.getString(R.string.Speech_Response_Non_Unread_Mail), true);
        } else if (speech.matches(res.getString(R.string.Speech_Keyword_ReadMail))) {

            if (!voicetivity.mailClient.getAllMails().isEmpty()) {
                voicetivity.state = new MailVtStateFive(voicetivity);
            } else
                voicetivity.speak(res.getString(R.string.Speech_Response_No_Mail_Downloaded), false);
        } else
            voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);


    }

    @Override
    public void onHelpRequest() {
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_CheckMail_Command), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadMail_Command), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_Get_Out),false);


    }


}
