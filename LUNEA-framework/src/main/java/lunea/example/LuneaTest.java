/**
 * LuneaTest.java 
 * 
 * $Author: $ 
 * $Date: $ 
 * $Revision: $
 */
package lunea.example;

import lunea.SequencedScheduler;

/**
 * @author Mike
 */
public class LuneaTest {

    public static void main(String[] args) {

        // Redefinimos el onFrameFinish() para "ver" cosas
        SequencedScheduler scheduler = new SequencedScheduler() {

            protected void onBeginFrame() {
                System.out.println(".");
                // En vez de pintar un ".", podríamos esperar el resto del ciclo
                // para cumplir con los FPS definidos
            }
        };

        // Agregamos N relojes
        int N = 10;
        for (int i = 1; i <= N; i++) {
            Clock clock = new Clock(Integer.toString(i), 0) {

                protected void onStartCicle() {
                    System.out.print(getName());
                }
            }; // El reloj principal será de 1 segundo
            clock.setZorder(i);
            scheduler.add(clock);
        }

        // Reloj X
        CiclicZorderClock clockX = new CiclicZorderClock("X", 0, 10) {

            protected void onStartCicle() {
                System.out.print(getName());
            }
        }; // El reloj principal será de 1 segundo
        clockX.setZorder(0);
        scheduler.add(clockX);

        scheduler.start();
    }
}