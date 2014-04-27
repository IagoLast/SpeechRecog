package es.udc.iagolast.speechrecog.speechrecog.mailClient;

public class Mail {

    private String subject;
    private String from;
    private String body;
    private Boolean read;

    public Mail(String subject, String from, String body) {
        this.subject = subject;
        this.from = from;
        this.body = body;
        this.read = null;
    }

    public Mail(String subject, String from, String body, boolean read) {
        this.subject = subject;
        this.from = from;
        this.body = body;
        this.read = read;
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

    public Boolean getRead() {
        return read;
    }

}
