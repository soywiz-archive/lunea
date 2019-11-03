/**
 * SequencedScheduler.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea;

/**
 * @author Mike
 */
public class SequencedScheduler extends Scheduler {

    private static final boolean DEBUG = false;

    protected int currentProcessIndex;

    public synchronized void add(Process process) {
        this.processes.add(process);
        process.setScheduler(this);
        new Thread(process).start();
    }

    public synchronized void start() {
        sortProcesses();
        Process process = this.processes.get(0);
        synchronized (process) {
            if (DEBUG)
                System.out.println("Notificamos al thread del proceso: "
                        + process);
            process.notify();
        }
    }

    @Override
    public void await(Process process) {
        // Sólo actuaremos si hay más de 1 thread
        if (this.processes.size() > 1) {

            // Obtenemos el siguiente índice de proceso
            currentProcessIndex++;
            currentProcessIndex = currentProcessIndex % this.processes.size();

            // Si estamos al principio, reordenamos!
            if (currentProcessIndex == 0) {
                sortProcesses();
                onBeginFrame();
            }

            // Buscamos el proceso
            Process nextProcess = this.processes.get(currentProcessIndex);

            // Si es el mismo, no hay que hacer nada, pero si es distinto
            // debemos arrancarlo y parar el actual
            if (nextProcess != process) {
                // Arrancamos el nuevo
                if (DEBUG)
                    System.out.println("Notificamos al thread del proceso: "
                            + nextProcess);
                synchronized (nextProcess) {
                    nextProcess.notify();
                }

                // Paramos el anterior
                if (DEBUG)
                    System.out.println("Paramos el thread del proceso: "
                            + process);

                synchronized (process) {
                    try {
                        process.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }
}