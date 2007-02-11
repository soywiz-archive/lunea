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

    // El array ordenado de procesos en ejecuci�n
    protected List<Process> processes;

    /**
     * Constructor por defecto
     */
    public Scheduler() {
        // Inicializamos la lista de procesos
        this.processes = new ArrayList<Process>();
    }

    /**
     * M�todo que invocan los procesos para esperar al siguiente ciclo
     */
    public abstract void await(Process process);

    /**
     * Reordena procesos en funci�n de su Z order
     * 
     */
    protected void sortProcesses() {
        Collections.sort(this.processes);
    }
    
    /**
     * Gancho para acciones a realizar tras la finalizaci�n de la ejecuci�n de
     * los Threads. Por defecto no hace nada.
     */
    protected void onBeginFrame() {
    }
}