/** Helper functions for unit tests involving real numbers
 *
 * Not intended for inclusion in a standard library.
 */
module etc.realtest;

import std.stdio;
import std.math;

/**
  Test the consistency of a real function which can be calculated in two ways.

  Returns the worst (minimum) value of feqrel(firstfunc(x), secondfunc(x))
  for all x in the domain.

Params:
        firstfunc  = First calculation method
        secondfunc = Second calculation method

        domain   = A sequence of pairs of numbers giving the first and last
                   points which are valid for the function.
Domain_Examples:
            (-real.infinity, real.infinity) ==> valid everywhere

            (-real.infinity, -real.min, real.min, real.infinity) ==> valid for x!=0.
 Returns:
    The number of bits for which firstfunc(x) and secondfunc(x) are equal for
    every point x in the domain.

    -1 = at least one point is wrong by a factor of 2 or more.
*/
int consistencyTwoFuncs(real function (real) firstfunc,
                    real function (real) secondfunc, real [] domain ...)
{
   /*  Author: Don Clugston. License: Public Domain
   */
      assert(domain.length>=2); // must have at least one valid range
      assert((domain.length & 1) == 0); // must have even number of endpoints.

      int worsterror=real.mant_dig+1;
      real worstx=domain[0]; // where does the biggest discrepancy occur?

      void testPoint(real x) {
         for (int i=0; i<domain.length; i+=2) {
            if (x>=domain[i] && x<=domain[i+1]) {
                int u=feqrel(secondfunc(x), firstfunc(x));
                if (u<worsterror) { worsterror=u;  worstx=x; }
                return;
             }
         }
      }
      // test the edges of the domains
      foreach(real y; domain) testPoint(y);
      real x = 1.01;
      // first, go from 1 to infinity
      for (x=1.01; x!=x.infinity; x*=2.83) testPoint(x);
      // then from 1 to +0
      for (x=0.98; x!=0; x*=0.401) testPoint(x);
      // from -1 to -0
      for (x=-0.93; x!=0; x*=0.403) testPoint(x);
      // from -1 to -infinity
      for (x=-1.09; x!=-x.infinity; x*=2.97) testPoint(x);

    if (worsterror>real.mant_dig) { writefln("Domain has zero size!"); assert(0); }
/*
    writefln("Worst error is ", worsterror, " at x= ", worstx, " Func1=%a, Func2=%a", firstfunc(worstx), secondfunc(worstx));
*/
      return worsterror;
}

/**
 Test the consistency of a real function which has an inverse.
 Equivalent to consistencyTwoFuncs(x, inversefunc(forwardfunc(x)), domain);
*/
int consistencyRealInverse(real function (real) forwardfunc,
                    real function (real) inversefunc, real [] domain ...)
{
 // HACK: should use proper function composition instead
  static real function (real) fwd;
  static real function (real) inv;
  static real unity(real x) { return x; }
  static real inverter(real x){ return inv(fwd(x)); }
  fwd = forwardfunc;
  inv=inversefunc;
  return consistencyTwoFuncs(&unity, &inverter, domain);
}