// Web host: battery saves live in /saves (<exe dir>/saves; the exe dir is "/" here), backed by IndexedDB.
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
  // SDL must not suspend inside SDL_RenderPresent: only the frame wait sleeps (ASYNCIFY_IGNORE_INDIRECT).
  ENV.SDL_EMSCRIPTEN_ASYNCIFY = '0';
  ENV.MMX_LOG_CONSOLE = '1';   // Mega Man X ports log to a file by default; keep it in the console
  FS.mkdir('/saves');
  FS.mount(IDBFS, {}, '/saves');
  addRunDependency('snesweb-saves');
  FS.syncfs(true, function (err) {
    if (err) console.error('[snesweb] loading saves from IndexedDB failed', err);
    removeRunDependency('snesweb-saves');
    // the runner writes saves atomically on its own schedule; mirror /saves when it changes
    var last = '';
    setInterval(function () {
      var sig = '';
      try {
        FS.readdir('/saves').forEach(function (n) {
          if (n === '.' || n === '..') return;
          var st = FS.stat('/saves/' + n); sig += n + ':' + st.size + ':' + (+st.mtime) + ';';
        });
      } catch (e) { return; }
      if (sig === last) return;
      last = sig;
      FS.syncfs(false, function (e) {
        if (e) console.error('[snesweb] writing saves to IndexedDB failed', e);
        if (Module.onSavesSynced) Module.onSavesSynced(e);
      });
    }, 1000);
  });
});
