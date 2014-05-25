package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.os.AsyncTask;
import android.util.Log;

import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.Scanner;
import java.util.regex.Pattern;

import javax.mail.Flags;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
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


    private static String[] splitMultipart(String raw) {
        String separator = raw.split("\n")[0].trim();
        return raw.substring(separator.length() + 1).split(Pattern.quote(separator));
    }


    private static String cleanPart(String raw){
        StringBuilder builder = new StringBuilder();
        boolean headersRead = false;
        for (String line : raw.trim().split("\n")){
            line = line.trim();
            if (line.length() == 0){
                headersRead = true;
            }
            if (line.equals("--")){ // Signature separator
                break;
            }

            String lowLine = line.toLowerCase();
            boolean headerLine = lowLine.startsWith("content-") || lowLine.startsWith("charset=");

            if (headersRead || !(headerLine)){
                headersRead = true;
                builder.append(line);
                builder.append("\n");
                builder.append("\n");
            }
        }

        return cleanHTML(builder.toString());
    }


    private static String decodeContent(Part p) throws MessagingException, IOException {
        String raw;
        try {
            raw = (String) p.getContent();
        } catch (ClassCastException e){
            raw = readFullStream((InputStream) p.getContent());
        }

        if (p.isMimeType("text/html")){
            return cleanHTML(raw);
        } else if (p.isMimeType("text/*")){
            return raw;
        }


        String[] parts = splitMultipart(raw);
        for (String rawPart : parts){
            return cleanPart(rawPart);
        }

        return null;
    }


    private IMAPMail processMessage(Message msg) throws MessagingException, IOException {
        // Extract headers
        IMAPMail mail = new IMAPMail();
        mail.setRead(msg.isSet(Flags.Flag.SEEN));
        msg.setFlag(Flags.Flag.SEEN, true);
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
            inbox.open(Folder.READ_WRITE); // Write to mark messages as read

            // Mail processing
            return processMessages(inbox.getMessages());


        } catch (MessagingException e) {
            e.printStackTrace();
            return null;
        }
    }


}
