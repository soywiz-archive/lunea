/**
 * Clock.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea.example;

import lunea.Process;

/**
 * Ejemplo de proceso Lunea que simplemente espera un lapso de tiempo.
 * Proporciona hooks para antes y después del lapso
 * 
 * @author Mike
 */
public class Clock extends Process {

    protected long period;

    protected Clock(String name, long period) {
        super(name);
        this.period = period;
    }

    public void execute() {
        while (true) {
            // gancho al comienzo
            onStartCicle();

            // El reloj simplemente espera el tiempo indicado
            try {
                Thread.sleep(period);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // gancho al final
            onFinishCicle();

            // Y completa su ciclo
            frame();
        }
    }

    protected void onStartCicle() {
    }

    protected void onFinishCicle() {
    }
}