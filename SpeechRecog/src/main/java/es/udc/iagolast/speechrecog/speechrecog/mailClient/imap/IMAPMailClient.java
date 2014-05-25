package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.AsyncTask;
import android.os.IBinder;
import android.util.Log;

import org.apache.commons.mail.Email;
import org.apache.commons.mail.EmailException;
import org.apache.commons.mail.SimpleEmail;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

public class IMAPMailClient implements MailClient {

    private String username, password;
    private Context context;
    private Intent serviceIntent;
    private IMAPClientService imapClientService;
    private boolean bound = false;

    private List<IMAPMail> currentMailList;
    private int currentMailListIndex = 0;


    private void bindService() {
        serviceIntent = new Intent(context, IMAPClientService.class);
        serviceIntent.putExtra(IMAPClientService.USERNAME, username);
        serviceIntent.putExtra(IMAPClientService.PASSWORD, password);
        context.startService(serviceIntent);
        Log.d("SpeechRecog/IMAPMailClient", "binding service");
        context.bindService(serviceIntent, clientServiceConnection, Context.BIND_AUTO_CREATE);
        Log.d("SpeechRecog/IMAPMailClient", "service bound");
    }


    private ServiceConnection clientServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder bind) {
            Log.d("SpeechRecog/IMAPMailClient", "connection!");
            IMAPClientService.SimpleBinder sBinder = (IMAPClientService.SimpleBinder) bind;
            imapClientService = sBinder.getService();
            bound = true;
            Log.d("SpeechRecog/IMAPMailClient", "bound = true");
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            bound = false;
        }
    };


    public IMAPMailClient(String username, String password, Context context) {
        this.username = username;
        this.password = password;
        this.context = context;

        bindService();
    }


    @Override
    public boolean hasUnreadMail() {
        List<IMAPMail> mailList = imapClientService.getMailList();
        for (IMAPMail mail : mailList){
            if (!mail.getRead()){
                return true;
            }
        }
        return false;
    }

    @Override
    public List<Mail> getUnreadMails() {
        List<IMAPMail> mailList = imapClientService.getMailList();

        // Linked list para poder añadirlos al principio sin perder rendimiento, y así mantener
        // el orden
        LinkedList<Mail> unreadMailList = new LinkedList<Mail>();

        for (IMAPMail mail : mailList){
            if (!mail.getRead()){
                unreadMailList.addFirst(mail);
            }
        }

        return unreadMailList;
    }

    @Override
    public List<Mail> getAllMails() {
        List<IMAPMail> mailList = imapClientService.getMailList();

        // Se copia superficialmente la lista para evitar efectos secundarios en su manejo
        LinkedList<Mail> copiedMailList = new LinkedList<Mail>();

        for (IMAPMail mail : mailList){
            copiedMailList.addFirst(mail);
        }

        return copiedMailList;
    }

    @Override
    public Mail getNextMail() {
        if (currentMailList == null){
            currentMailList = imapClientService.getMailList();
        }

        try {
            return currentMailList.get(currentMailListIndex++);
        } catch (IndexOutOfBoundsException e){
            currentMailListIndex = 0;

            imapClientService.refresh();
            return null;
        }
    }

    @Override
    public Mail getNextUnreadMail() {
        for (IMAPMail mail : imapClientService.getMailList()){
            if (!mail.getRead()){
                mail.setRead(true);

                if (!hasUnreadMail()){
                    imapClientService.refresh();
                }
                return mail;
            }
        }

        return null;
    }

    @Override
    public boolean sendMail(Mail mail) {
        ArrayList<InternetAddress> recv = new ArrayList<InternetAddress>(1);
        final String destination = mail.getTo();

        // Fill email data
        SimpleEmail email = new SimpleEmail();
        try {
            recv.add(new InternetAddress(destination));
            email.setTo(recv);

            email.setSubject(mail.getSubject());
            email.setFrom(mail.getFrom());
            email.setMsg(mail.getBody());
        } catch (AddressException e) {
            e.printStackTrace();
            return false;
        } catch (EmailException e) {
            e.printStackTrace();
            return false;
        }

        // Set Server data
        email.setAuthentication(username.split("@")[0], password);
        email.setHostName("smtp.gmail.com");
        email.setSSLOnConnect(true);
        email.setSSLCheckServerIdentity(true);

        final Email definitiveMail = email;

        // Send mail on a separate thread
        new AsyncTask<Void, Void, Void>(){

            @Override
            protected Void doInBackground(Void... voids) {
                try {
                    definitiveMail.send();
                } catch (EmailException e) {
                    e.printStackTrace();
                    Log.e("IMAPMailClient", "Error sending mail to " + destination);
                }

                return null;
            }
        }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        return true;
    }
}