package es.udc.iagolast.speechrecog.speechrecog.mailClient;

/**
 * Created by dani on 24/04/14.
 */
public class Mail {

    private String subject;
    private String from;
    private String body;


    public Mail(String subject, String from, String body) {
        this.subject = subject;
        this.from = from;
        this.body = body;

    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getFrom() {
        return from;
    }

    public void setFrom(String from) {
        this.from = from;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }


}
