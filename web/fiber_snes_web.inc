/* Web build: the Win32-style fiber API over Emscripten fibers (Asyncify unwinds and rewinds the C stack;
 * build with full Asyncify). Snapshots of a fiber stack are not possible here. */
#include <emscripten/fiber.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct WebFiber {
    emscripten_fiber_t ctx;
    int is_thread;
    FiberProc entry;
    void *param;
    char *cstack, *astack;
} WebFiber;

#define WEB_FIBER_ASYNCIFY_STACK ((size_t)4u << 20)
static WebFiber *s_web_current;

static void web_fiber_trampoline(void *p)
{
    WebFiber *f = (WebFiber *)p;
    f->entry(f->param);
    fprintf(stderr, "[fiber] entry returned\n");
    abort();
}

void *ConvertThreadToFiber(void *param)
{
    (void)param;
    if (s_web_current) return s_web_current;
    WebFiber *f = (WebFiber *)calloc(1, sizeof *f);
    if (!f) return NULL;
    f->is_thread = 1;
    f->astack = (char *)malloc(WEB_FIBER_ASYNCIFY_STACK);
    if (!f->astack) { free(f); return NULL; }
    emscripten_fiber_init_from_current_context(&f->ctx, f->astack, WEB_FIBER_ASYNCIFY_STACK);
    s_web_current = f;
    return f;
}

void *CreateFiber(size_t stack_size, FiberProc entry, void *param)
{
    if (!entry) return NULL;
    if (stack_size < ((size_t)256u << 10)) stack_size = (size_t)256u << 10;
    WebFiber *f = (WebFiber *)calloc(1, sizeof *f);
    if (!f) return NULL;
    f->entry = entry; f->param = param;
    f->cstack = (char *)malloc(stack_size);
    f->astack = (char *)malloc(WEB_FIBER_ASYNCIFY_STACK);
    if (!f->cstack || !f->astack) { free(f->cstack); free(f->astack); free(f); return NULL; }
    emscripten_fiber_init(&f->ctx, web_fiber_trampoline, f, f->cstack, stack_size, f->astack, WEB_FIBER_ASYNCIFY_STACK);
    return f;
}

void SwitchToFiber(void *fiber)
{
    WebFiber *to = (WebFiber *)fiber, *from = s_web_current;
    if (!to || to == from) return;
    if (!from) { fprintf(stderr, "[fiber] SwitchToFiber before ConvertThreadToFiber\n"); abort(); }
    s_web_current = to;
    emscripten_fiber_swap(&from->ctx, &to->ctx);
}

void DeleteFiber(void *fiber)
{
    WebFiber *f = (WebFiber *)fiber;
    if (!f || f == s_web_current || f->is_thread) return;
    free(f->cstack); free(f->astack); free(f);
}

unsigned long GetLastError(void) { return 0; }
int    FiberSnapshotSupported(void) { return 0; }
size_t FiberSnapshotBound(void *fiber) { (void)fiber; return 0; }
size_t FiberSnapshotSave(void *fiber, void *out, size_t capacity) { (void)fiber; (void)out; (void)capacity; return 0; }
int    FiberSnapshotLoad(void *fiber, const void *in, size_t size) { (void)fiber; (void)in; (void)size; return 0; }
