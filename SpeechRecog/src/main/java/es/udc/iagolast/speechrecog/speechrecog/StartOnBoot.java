package es.udc.iagolast.speechrecog.speechrecog;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class StartOnBoot extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Intent sIntent = new Intent(context, SpeechRecognitionService.class);
        context.startService(sIntent);
    }
}