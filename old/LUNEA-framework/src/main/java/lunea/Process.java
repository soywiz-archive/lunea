/**
 * Process.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea;

/**
 * @author Mike
 */
public abstract class Process implements Runnable, Comparable {

    // El nombre del proceso, �til para debugar
    private String name;

    // Este es el orden de planificaci�n
    private int zorder;

    // El planificador, que gestiona el sincronismo entre procesos
    private Scheduler scheduler;

    public Process() {
    }

    public Process(String name) {
        this.name = name;
    }

    public String toString() {
        return "Process[" + (name == null ? "" : name) + ":" + hashCode() + "]";
    }

    public String getName() {
        return name;
    }

    public void run() {
        // Debemos entrar en espera de que nos den paso
        try {
            synchronized (this) {
                wait();
            }
        } catch (InterruptedException e1) {
            // TODO Auto-generated catch block
            e1.printStackTrace();
        }
        execute();
    }

    protected abstract void execute();

    // Esta es la llamada a esperar al resto de Threads
    protected void frame() {
        scheduler.await(this);
    }

    // Fija la barreda de sincronizaci�n. S�lo lo deber�a usar clases de este
    // paquete
    void setScheduler(Scheduler scheduler) {
        this.scheduler = scheduler;
    }

    /**
     * Retorna el orden Z del proceso
     * 
     * @return
     */
    public int getZorder() {
        return zorder;
    }

    /**
     * Establece el orden Z del proceso
     * 
     * @param zorder
     */
    public void setZorder(int zorder) {
        this.zorder = zorder;
    }

    public int compareTo(Object o) {
        return getZorder() - ((Process) o).getZorder();
    }
}