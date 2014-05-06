package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;

import java.util.List;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService.SimpleBinder;
import es.udc.iagolast.speechrecog.speechrecog.adapters.VtAdapter;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

public class MainActivity extends Activity {

    private SpeechRecognitionService speechRecognitionService;
    private ListView listView;
    private List<Voicetivity> voicetivityList;
    private VtAdapter vtAdapter;
    private Intent intent;
    private boolean bound;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        intent = new Intent(this, SpeechRecognitionService.class);
        startService(intent);
        loadUI();
        setListeners();
    }

    @Override
    protected void onStart() {
        bindSpeechRecognizer(intent);
        super.onStart();
    }

    @Override
    protected void onStop() {
        if (bound) {
            unbindService(speechRecogniterConnection);
        }
        bound = false;
        super.onStop();
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
    private void bindSpeechRecognizer(Intent intent) {
        bindService(intent, speechRecogniterConnection, Context.BIND_AUTO_CREATE);
    }

    /**
     * Service connection que asigna una voicetivity y empieza a escuchar cuando se conecta.
     */
    private ServiceConnection speechRecogniterConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder bind) {
            SimpleBinder sBinder = (SimpleBinder) bind;
            speechRecognitionService = sBinder.getService();
            voicetivityList = VoicetivityManager.getInstance(speechRecognitionService).getVoicetivityList();
            populateListView(voicetivityList);
            bound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            bound = false;
        }
    };

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_exit:
                unbindService(speechRecogniterConnection);
                bound = false;
                stopService(intent);
                finish();
                break;
            case R.id.action_settings:
                startActivity(new Intent(this, SettingsActivity.class));
                break;
            default:
                return super.onOptionsItemSelected(item);
        }
        return super.onOptionsItemSelected(item);
    }

}
