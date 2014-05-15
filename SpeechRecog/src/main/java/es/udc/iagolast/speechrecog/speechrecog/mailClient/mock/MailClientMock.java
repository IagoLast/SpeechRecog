package es.udc.iagolast.speechrecog.speechrecog.mailClient.mock;

import java.util.LinkedList;
import java.util.List;
import java.util.Stack;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;


public class MailClientMock implements MailClient {

    Stack<Mail> unreadMailStack;
    List<Mail> readMails;
    int index = 0;


    private final String TO_MAIL_STRING = "mimail@mail.com";

    public MailClientMock() {

        Mail readMail1 = new Mail("Tu pedido de Amazon.es ha sido enviado", "confirmar-envio@amazon.es", TO_MAIL_STRING, "Estimado cliente: El pedido de código 1232442 te llegará el día 15.");
        Mail readMail2 = new Mail("Idea para Mail", "mail.desconocido@gmail.com", TO_MAIL_STRING, "Aquí tienes mi idea para rellenar un mail de ejemplo. Saludos.");
        Mail readMail3 = new Mail("Mail de confirmación de asistencia al evento", "confirmacion@evento.com", TO_MAIL_STRING, "Hola, necesitamos su confirmación de que asistirá al evento Carrera de camellos este Sábado. Saludos");

        Mail unreadMail1 = new Mail("Quedar para hacer Robótica", "iago.lastra@gmail.com", TO_MAIL_STRING, "Hola, quedamos a las cinco para hacer robótica?");
        Mail unreadMail2 = new Mail("Concierto Extremoduro", "iago.lastra@gmail.com", TO_MAIL_STRING, "Eh, hay que coger las entradas para el concierto!");
        Mail unreadMail3 = new Mail("Entrega práctica de la asignatura", "soy.un.profesor@udc.es", TO_MAIL_STRING, "La entrega de la última práctica se aplaza al día 15. Saludos");

        unreadMailStack = new Stack<Mail>();
        readMails = new LinkedList<Mail>();

        unreadMailStack.push(unreadMail1);
        unreadMailStack.push(unreadMail2);
        unreadMailStack.push(unreadMail3);

        readMails.add(readMail1);
        readMails.add(readMail2);
        readMails.add(readMail3);

    }

    @Override
    public boolean hasUnreadMail() {
        return !unreadMailStack.isEmpty();
    }

    @Override
    public Stack<Mail> getUnreadMails() {
        return unreadMailStack;
    }

    @Override
    public List<Mail> getAllMails() {
        return readMails;
    }

    @Override
    public Mail getNextMail() {
        try {
            return readMails.get(index++);
        } catch (IndexOutOfBoundsException e) {
            index = 0;
            return null;
        }

    }

    @Override
    public Mail getNextUnreadMail() {
        if (!unreadMailStack.isEmpty()) {
            readMails.add(unreadMailStack.peek());
            return unreadMailStack.pop();
        } else return null;

    }

    @Override
    public boolean sendMail(Mail mail) {
        return (Math.random() > 0.5);


    }
}
