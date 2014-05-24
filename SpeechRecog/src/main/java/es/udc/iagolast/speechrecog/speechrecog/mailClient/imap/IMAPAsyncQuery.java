package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.os.AsyncTask;
import android.util.Log;

import com.sun.mail.imap.IMAPInputStream;
import com.sun.mail.util.QPDecoderStream;

import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.Scanner;

import javax.mail.Address;
import javax.mail.BodyPart;
import javax.mail.Flags;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Part;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.internet.MimeUtility;

public class IMAPAsyncQuery extends AsyncTask<Void, Void, List<IMAPMail>> {

    private static final String TAG = "SpeechRecog/IMAPAsyncQuery";
    private String username, password;


    public IMAPAsyncQuery(String username, String password) {
        this.username = username;
        this.password = password;
    }

    private static String cleanHTML(String html){
        HtmlCleaner cleaner = new HtmlCleaner();
        TagNode node = cleaner.clean(html);

        return String.valueOf(node.getText());
    }

    private static String readFullStream(InputStream stream) {
        Scanner s = new Scanner(stream).useDelimiter("\\A");
        return s.hasNext() ? s.next() : "";
    }


    private static String cleanStream(InputStream stream){
        return cleanString(readFullStream(stream));
    }


    private static String cleanString(String input) {
        Log.d(TAG, "String: " + input);

        String [] chunks = input.split("On ");
        return chunks[0];

        //return input;
    }


    private String decodeContent(Part p) throws MessagingException, IOException {
        // Text, just clean it
        if (p.getContentType().startsWith("text/")){
            try {
                return cleanString((String) p.getContent());
            } catch (ClassCastException e){
                return cleanStream((InputStream) p.getContent());
            }


        // Multiparted
        } else if (p.getContentType().startsWith("multipart/")) {
            // prefer plain text > html > unknown type
            Multipart mp = (Multipart) p.getContent();

            String text = null;
            for (int i = 0; i < mp.getCount(); i++) {
                Part bp = mp.getBodyPart(i);
                if (bp.isMimeType("text/plain")) {
                    String s = decodeContent(bp);
                    if (s != null){
                        return s;
                    }
                } else if (bp.isMimeType("text/html")) {
                    text = decodeContent(bp);

                } else {
                    if (text == null){
                        text = decodeContent(bp);
                    }
                }
            }
            return text;

        }

        return null;
    }


    private IMAPMail processMessage(Message msg) throws MessagingException, IOException {
        // Extract headers
        IMAPMail mail = new IMAPMail();
        mail.setRead(msg.isSet(Flags.Flag.SEEN));
        try {
            mail.setFrom(MimeUtility.decodeText(msg.getFrom()[0].toString()));
            mail.setTo(MimeUtility.decodeText(msg.getReplyTo()[0].toString()));
            mail.setSubject(MimeUtility.decodeText(msg.getSubject()));
        } catch (UnsupportedEncodingException e) {
            throw new MessagingException("UnsupportedEncodingException");
        }

        String body = decodeContent(msg);
        if (body == null){
            body = "Cannot decode";
        }
        mail.setBody(body);

        return mail;
    }


    private List<IMAPMail> processMessages(Message[] originalMessageList){
        List<IMAPMail> mailList = new ArrayList<IMAPMail>(originalMessageList.length);
        for (Message msg : originalMessageList){
            try {
                mailList.add(processMessage(msg));
            } catch (MessagingException e) {
                e.printStackTrace();
            } catch (IOException e){
                e.printStackTrace();
            }
        }
        return mailList;
    }

    @Override
    protected List<IMAPMail> doInBackground(Void... voids) {

        // Connection and logging in
        Properties props = new Properties();
        props.setProperty("mail.store.protocol", "imaps");
        try {
            Session session = Session.getInstance(props, null);
            Store store = session.getStore();
            store.connect("imap.gmail.com", username, password);

            // Navigation
            Folder inbox = store.getFolder("INBOX");
            inbox.open(Folder.READ_ONLY);

            // Mail processing
            return processMessages(inbox.getMessages());


        } catch (MessagingException e) {
            e.printStackTrace();
            System.err.println("IMAP-- NULL, error, agh!");
            return null;
        }
    }


}
