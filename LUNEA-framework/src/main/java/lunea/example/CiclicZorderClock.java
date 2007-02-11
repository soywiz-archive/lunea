/**
 * Clock.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea.example;

/**
 * Ejemplo de proceso Lunea que simplemente espera un lapso de tiempo.
 * Proporciona hooks para antes y después del lapso
 * 
 * @author Mike
 */
public class CiclicZorderClock extends Clock {

    protected int maxZorder;

    protected CiclicZorderClock(String name, long period, int maxZorder) {
        super(name, period);
        this.maxZorder = maxZorder;
    }

    protected void onFinishCicle() {
        setZorder((getZorder() + 1) % maxZorder);
    }
}