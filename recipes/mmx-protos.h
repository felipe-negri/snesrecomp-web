/* Prototypes mmx_rtl.c calls without declaring (vectors of the generated code). Native builds tolerate the
 * implicit int return; WebAssembly traps on the mismatched signature, so the web build force-includes these. */
#ifndef MMX_WEB_PROTOS_H
#define MMX_WEB_PROTOS_H
struct CpuState;
void I_IRQ(struct CpuState *cpu);
void I_NMI(struct CpuState *cpu);
void I_RESET(struct CpuState *cpu);
#endif
