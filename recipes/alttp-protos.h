/* Prototypes some ALttP sources call without declaring. Native builds tolerate the implicit int
 * return; WebAssembly traps on the mismatched signature, so the web build force-includes these. */
#ifndef ALTTP_WEB_PROTOS_H
#define ALTTP_WEB_PROTOS_H
struct CpuState;
void keybinds_init(const char *exe_path);
void MkDir(const char *s);
void ZeldaAdjustSpritePrepHorizontalCull(struct CpuState *cpu);
void I_IRQ(struct CpuState *cpu);
#endif
