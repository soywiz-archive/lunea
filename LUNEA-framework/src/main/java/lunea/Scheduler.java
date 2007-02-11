/**
 * BarrierScheduler.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * @author Mike
 */
public abstract class Scheduler {

    // El array ordenado de procesos en ejecución
    protected List<Process> processes;

    /**
     * Constructor por defecto
     */
    public Scheduler() {
        // Inicializamos la lista de procesos
        this.processes = new ArrayList<Process>();
    }

    /**
     * Método que invocan los procesos para esperar al siguiente ciclo
     */
    public abstract void await(Process process);

    /**
     * Reordena procesos en función de su Z order
     * 
     */
    protected void sortProcesses() {
        Collections.sort(this.processes);
    }
    
    /**
     * Gancho para acciones a realizar tras la finalización de la ejecución de
     * los Threads. Por defecto no hace nada.
     */
    protected void onBeginFrame() {
    }
}