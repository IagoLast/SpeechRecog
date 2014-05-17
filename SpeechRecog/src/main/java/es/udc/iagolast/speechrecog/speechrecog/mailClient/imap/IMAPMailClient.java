package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.content.res.Resources;
import android.os.AsyncTask;
import android.util.Log;

import org.apache.commons.mail.Email;
import org.apache.commons.mail.EmailException;
import org.apache.commons.mail.SimpleEmail;
import org.apache.commons.net.imap.IMAPClient;
import org.apache.commons.net.imap.IMAPSClient;

import java.io.IOException;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;

public class IMAPMailClient implements MailClient {

    IMAPClientService clientService;
    List<IMAPMail> mailList = new ArrayList<IMAPMail>();
    int index = 0;
    final static private int TIMEOUT = 60000;
    private String userName, password;

    public void addMail(IMAPMail mail) {
        mailList.add(mail);
    }

    private class IMAPClientService extends AsyncTask<Void, Void, Void> {

        IMAPClient client;
        String userName;
        String password;
        String host;
        int port;
        IMAPMailClient iface;
        Resources res;

        public IMAPClientService(String userName, String password,
                                 String host, int port, IMAPMailClient iface,
                                 Resources res) {
            this.userName = userName;
            this.password = password;
            this.host = host;
            this.port = port;
            this.iface = iface;
            this.res = res;
        }


        @Override
        protected Void doInBackground(Void... voids) {
            Log.d("IMAPClient/SpeechRecog", "Connecting client");
            client = new IMAPSClient("TLS", true);
            client.setDefaultTimeout(TIMEOUT);
            client.setConnectTimeout(TIMEOUT);
            Log.d("IMAPClient/SpeechRecog", "Client AddListener");
            client.addProtocolCommandListener(new IMAPListener(iface, client, res));
            try {
                Log.d("IMAPClient/SpeechRecog", "Client connecting");
                client.connect(host, port);
                Log.d("IMAPClient/SpeechRecog", "Client connected");
                if (!client.login(userName, password)) {
                    client.disconnect();
                    return null;
                }
                Log.d("IMAPClient/SpeechRecog", "Client selects");
                client.select("inbox");
                Log.d("IMAPClient/SpeechRecog", "Client searches");
                client.search("UNANSWERED");
                Log.d("IMAPClient/SpeechRecog", "Client expects");

            } catch (IOException e) {
                Log.d("IMAPClient/SpeechRecog", "Client crashed");
                e.printStackTrace();
            }

            return null;
        }
    }

    public IMAPMailClient(String userName, String password, String host, int port, Resources res) {
        this.userName = userName;
        this.password = password;

        clientService = new IMAPClientService(userName, password, host, port, this, res);
        clientService.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }


    /// @NOTE Don't call from UI thread
    public static boolean checkCredentials(String userName, String password,
                                           String host, int port) {

        boolean validCredentials = false;
        IMAPSClient client = new IMAPSClient("TLS", true);
        client.setDefaultTimeout(TIMEOUT);
        client.setConnectTimeout(TIMEOUT);
        try {
            Log.d("IMAPClient/SpeechRecog", "Cred-checker connecting");
            client.connect(host, port);
            Log.d("IMAPClient/SpeechRecog", "Cred-checker connected");

            validCredentials = client.login(userName, password);
            client.disconnect();
        } catch (SocketException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return validCredentials;
    }


    @Override
    public boolean hasUnreadMail() {
        for (IMAPMail mail : mailList) {
            if (!mail.getRead()) {
                return true;
            }
        }
        return false;
    }

    @Override
    public List<Mail> getUnreadMails() {
        List<Mail> unreadMail = new ArrayList<Mail>();
        for (IMAPMail mail : mailList) {
            if (!mail.getRead()) {
                unreadMail.add(mail);
            }
        }
        return unreadMail;
    }

    @Override
    public List<Mail> getAllMails() {
        // Copiamos la lista para que los cambios de una no afecten a otra
        List<Mail> safeMailList = new ArrayList<Mail>(mailList.size());
        for (IMAPMail mail : mailList) {
            safeMailList.add(mail);
        }
        return safeMailList;
    }

    @Override
    public Mail getNextMail() {
        try {
            return mailList.get(index++);
        } catch (IndexOutOfBoundsException e) {
            index = 0;
            return null;
        }
    }

    @Override
    public Mail getNextUnreadMail() {
        for (IMAPMail mail : mailList) {
            if (!mail.getRead()) {
                mail.setRead(true);
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
        email.setAuthentication(userName, password);
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