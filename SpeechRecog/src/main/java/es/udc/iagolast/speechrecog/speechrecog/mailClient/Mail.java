package es.udc.iagolast.speechrecog.speechrecog.mailClient;

public class Mail {

    private String subject;
    private String from;
    private String to;
    private String body;

    public Mail(String subject, String from, String to, String body) {
        this.subject = subject;
        this.from = from;
        this.to = to;
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

    public String getTo() {
        return to;
    }

    public void setTo(String to) {
        this.to = to;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

}
