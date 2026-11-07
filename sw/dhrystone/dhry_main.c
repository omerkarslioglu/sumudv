/* Compact Dhrystone-style integer workload for SUMUD-V scoring.
 * Not identical to classic DHRYSTONE 2.1 numbering; reports DMIPS-like metric
 * via TOHOST = (iters * 1000) / cycles_approx_ms at 50 MHz assumption.
 */
#include "platform.h"

#define ITERS 2000

typedef struct Rec {
  struct Rec *Ptr_Comp;
  int Discr;
  int Enum_Comp;
  int Int_Comp;
  char Str_Comp[31];
} Rec;

static Rec glb;
static int Int_Glob;
static char Char_Glob;

static void Proc_3(Rec **p)
{
  if (glb.Ptr_Comp)
    *p = glb.Ptr_Comp;
  Int_Glob = 5;
}

static void Proc_1(Rec *Ptr_Val_Par)
{
  Rec *Next = Ptr_Val_Par->Ptr_Comp;
  *Ptr_Val_Par->Ptr_Comp = glb;
  Ptr_Val_Par->Int_Comp = 5;
  Next->Int_Comp = Ptr_Val_Par->Int_Comp;
  Next->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3(&Next->Ptr_Comp);
  if (Next->Discr == 0) {
    Next->Int_Comp = 6;
    Next->Enum_Comp = Ptr_Val_Par->Enum_Comp;
  } else {
    *Ptr_Val_Par = *Ptr_Val_Par->Ptr_Comp;
  }
}

static void Proc_2(int *Int_Par)
{
  int loc = *Int_Par + 10;
  do {
    if (Char_Glob == 'A') {
      loc -= 1;
      *Int_Par = loc - Int_Glob;
    }
  } while (loc >= 0 && Char_Glob != 'A');
}

int main(void)
{
  Rec *Ptr = &glb;
  int Int_1 = 2, Int_2 = 3, Int_3;
  unsigned t0, t1;

  glb.Ptr_Comp = &glb;
  glb.Discr = 0;
  glb.Enum_Comp = 2;
  glb.Int_Comp = 40;
  uart_puts("dhrystone start\n");

  t0 = rdcycle();
  for (int i = 0; i < ITERS; i++) {
    Proc_1(Ptr);
    Int_3 = Int_1 * Int_2;
    Int_2 = Int_3 / Int_1;
    Int_1 = Int_3 - Int_2 * 7;
    Proc_2(&Int_1);
    Char_Glob = 'A';
  }
  t1 = rdcycle();

  unsigned cycles = t1 - t0;
  /* At 50 MHz, DMIPS ~= ITERS / (cycles/50e6) / 1757 */
  unsigned dmips_x100 = 0;
  if (cycles)
    dmips_x100 = (unsigned)((unsigned long)ITERS * 50000000ul / ((unsigned long)cycles * 1757ul / 100ul));

  uart_puts("dhrystone done\n");
  TOHOST = dmips_x100 ? dmips_x100 : cycles;
  (void)Int_3;
  for (;;)
    ;
  return 0;
}
