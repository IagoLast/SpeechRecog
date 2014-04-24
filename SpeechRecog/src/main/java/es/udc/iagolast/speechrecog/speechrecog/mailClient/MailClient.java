package es.udc.iagolast.speechrecog.speechrecog.mailClient;

import java.util.List;


public interface MailClient {

    public boolean hasUnreadMail();

    public List<Mail> getUnreadMails();

    public List<Mail> getAllMails();

    public Mail getNextMail();


}
