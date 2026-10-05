// Shared behavior for the reader prototypes. Each page supplies markup with data- hooks;
// this fills them in and keeps them in step as you move through Isaiah 40.
//
//   [data-focus]        replaced with the focus band
//   [data-menu]         filled with the ⋯ menu (data-menu="tree" adds the library hierarchy)
//   [data-ref] [data-n] [data-count] [data-work]   text updated on each move
//   [data-body]         the passage (gets the size class)
//   [data-note]         contenteditable note for the current verse; [data-note-status], [data-note-preview]
//   [data-prev] [data-next]   step buttons (data-label="verse" shows "‹ Verse 2")
//   [data-keep]         keep ribbon
//   [data-pop-toggle=id]      opens/closes #id; clicking outside or Esc closes
//   [data-vgrid] [data-vlist] [data-ruler]   verse pickers
//   [data-swipe]        left/right swipe steps on phones
(() => {
  const verses = window.VERSES;
  const notes = {
    1: "<p>Comfort comes first, before any demand. Holiness here starts as something God says to a people, not something they achieve.</p>",
    3: "<p>The way is prepared <em>in the wilderness</em>: the holy is met in the empty places.</p>",
    8: "<p>Grass and flower vs. the word. Is holiness a kind of permanence?</p>",
    25: "<p>“To whom then will ye liken me?” The holy as the incomparable.</p>",
    31: "<p>Strength renewed by waiting. Holiness as something received.</p>",
  };
  const kept = new Set([8, 31]);
  const R = (window.Reader = { verses, notes, kept, n: 1, listeners: [] });

  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  const sizeOf = (t) => (t.length > 450 ? "long" : t.length > 180 ? "mid" : "");
  const plain = (html) => { const d = document.createElement("div"); d.innerHTML = html; return d.textContent.trim(); };

  const FOCUS = `
    <section class="focus">
      <button class="focus-head" type="button" aria-expanded="false" title="About this focus">
        <span class="focus-label">Focus</span>
        <h1 class="focus-title">What does it mean to be holy?</h1>
        <span class="focus-caret">▾</span>
      </button>
      <div class="focus-body">
        <p>Not “set apart” as a dictionary word, but what it would look like in a life. Reading the second half of Isaiah for how holiness is described when it isn't about the temple.</p>
        <div class="focus-actions"><a href="#">Edit focus</a> · <a href="#">New focus</a> · <a href="#">All focuses</a></div>
      </div>
    </section>`;

  const MENU = (tree) => `
    ${tree ? `<div class="menu-head">Library</div>
    <div class="tree">
      <a href="#">Sacred Texts</a>
      <a href="#" style="padding-left:24px">Old Testament</a>
      <a href="#" style="padding-left:36px">Isaiah</a>
      <a href="#" class="here" style="padding-left:48px">Chapter 40</a>
    </div><div class="menu-sep"></div>` : ""}
    <a class="menu-item" href="#">All notes <small>5</small></a>
    <a class="menu-item" href="#">All focuses</a>
    <button class="menu-item" type="button">Recent places <kbd>h</kbd></button>
    <a class="menu-item" href="#">Search <kbd>/</kbd></a>
    <a class="menu-item" href="#">Random · Old Testament</a>
    <a class="menu-item" href="#">Kept</a>
    <div class="menu-sep"></div>
    <button class="menu-item" type="button" data-theme-toggle>Light / dark</button>
    <a class="menu-item" href="#">Sign out</a>`;

  R.go = (n) => {
    n = Math.max(1, Math.min(verses.length, n));
    if (n === R.n) return;
    R.n = n;
    history.replaceState(null, "", `#v${n}`);
    render(true);
  };
  R.next = () => R.go(R.n + 1);
  R.prev = () => R.go(R.n - 1);
  R.on = (fn) => R.listeners.push(fn);

  function render(moved) {
    const n = R.n, text = verses[n - 1], note = notes[n] || "";
    $$("[data-ref]").forEach((el) => (el.textContent = `Isaiah 40:${n}`));
    $$("[data-n]").forEach((el) => (el.textContent = n));
    $$("[data-count]").forEach((el) => (el.textContent = verses.length));
    $$("[data-body]").forEach((el) => {
      el.textContent = text;
      el.classList.remove("mid", "long", "turn");
      if (sizeOf(text)) el.classList.add(sizeOf(text));
      if (moved) { void el.offsetWidth; el.classList.add("turn"); }
    });
    $$("[data-note]").forEach((el) => { if (el !== document.activeElement || moved) el.innerHTML = note; });
    $$("[data-note-preview]").forEach((el) => {
      el.textContent = note ? plain(note) : "Write a note";
      el.classList.toggle("empty", !note);
    });
    $$("[data-note-status]").forEach((el) => (el.textContent = ""));
    $$("[data-prev]").forEach((el) => {
      el.disabled = n === 1;
      if (el.dataset.label) el.textContent = n > 1 ? `‹ ${el.dataset.label} ${n - 1}` : "";
    });
    $$("[data-next]").forEach((el) => {
      el.disabled = n === verses.length;
      if (el.dataset.label) el.textContent = n < verses.length ? `${el.dataset.label} ${n + 1} ›` : "Chapter 41 ›";
    });
    $$("[data-keep]").forEach((el) => {
      el.classList.toggle("kept", kept.has(n));
      el.title = kept.has(n) ? "Kept (b)" : "Keep this passage (b)";
    });
    $$("[data-vgrid] button, [data-vlist] button, [data-ruler] button").forEach((b) => {
      const v = +b.dataset.v;
      b.classList.toggle("here", v === n);
      b.classList.toggle("noted", !!notes[v]);
      b.classList.toggle("kept", kept.has(v));
      b.setAttribute("aria-current", v === n);
    });
    R.listeners.forEach((fn) => fn(n, moved));
  }

  function build() {
    $$("[data-focus]").forEach((el) => (el.outerHTML = FOCUS));
    $$("[data-menu]").forEach((el) => (el.innerHTML = MENU(el.dataset.menu === "tree")));
    $$("[data-vgrid]").forEach((el) => {
      el.classList.add("vgrid");
      el.innerHTML = verses.map((_, i) => `<button type="button" data-v="${i + 1}" title="Verse ${i + 1}">${i + 1}</button>`).join("");
    });
    $$("[data-vlist]").forEach((el) => {
      el.innerHTML = verses.map((t, i) =>
        `<button type="button" data-v="${i + 1}"><b>${i + 1}</b><span>${t}</span></button>`).join("");
    });
    $$("[data-ruler]").forEach((el) => {
      el.innerHTML = verses.map((_, i) => `<button type="button" data-v="${i + 1}" title="Verse ${i + 1}" aria-label="Verse ${i + 1}"></button>`).join("");
    });

    const letter = document.body.dataset.proto;
    const sw = document.createElement("nav");
    sw.className = "proto-switch";
    sw.innerHTML = ["a", "b", "c", "d", "e"].map((l) =>
      `<a href="${l}.html${location.hash}" class="${l === letter ? "on" : ""}" title="Layout ${l.toUpperCase()}">${l.toUpperCase()}</a>`).join("") +
      `<a href="index.html" title="All layouts">≡</a>`;
    document.body.append(sw);
  }

  const closePops = (except) => {
    $$(".pop.open").forEach((p) => { if (p !== except) p.classList.remove("open"); });
    $$("[data-pop-toggle]").forEach((b) => { if (!except || b.dataset.popToggle !== except.id) b.setAttribute("aria-expanded", "false"); });
    $$(".focus.open").forEach((f) => { f.classList.remove("open"); f.querySelector(".focus-head").setAttribute("aria-expanded", "false"); });
  };
  R.closePops = closePops;

  let saveTimer;
  function wire() {
    document.addEventListener("click", (e) => {
      const t = e.target;
      const v = t.closest("[data-v]");
      if (v) { R.go(+v.dataset.v); if (!v.closest("[data-ruler]")) closePops(); return; }
      if (t.closest("[data-prev]")) return R.prev();
      if (t.closest("[data-next]")) return R.next();
      if (t.closest("[data-keep]")) { kept.has(R.n) ? kept.delete(R.n) : kept.add(R.n); return render(); }
      if (t.closest("[data-theme-toggle]")) {
        const dark = matchMedia("(prefers-color-scheme: dark)").matches;
        const cur = document.documentElement.dataset.theme || (dark ? "dark" : "light");
        document.documentElement.dataset.theme = cur === "dark" ? "light" : "dark";
        return closePops();
      }
      const tool = t.closest("[data-tool]");
      if (tool) { e.preventDefault(); document.execCommand(tool.dataset.tool, false, tool.dataset.arg); return; }
      const toggle = t.closest("[data-pop-toggle]");
      if (toggle) {
        const pop = document.getElementById(toggle.dataset.popToggle);
        const open = !pop.classList.contains("open");
        closePops(pop);
        pop.classList.toggle("open", open);
        toggle.setAttribute("aria-expanded", open);
        return;
      }
      const head = t.closest(".focus-head");
      if (head) {
        const f = head.closest(".focus"), open = !f.classList.contains("open");
        closePops();
        f.classList.toggle("open", open);
        head.setAttribute("aria-expanded", open);
        return;
      }
      if (!t.closest(".pop, .focus-body")) closePops();
    });

    document.addEventListener("input", (e) => {
      const ed = e.target.closest("[data-note]");
      if (!ed) return;
      const html = ed.innerHTML.trim(), empty = !ed.textContent.trim();
      if (empty) delete notes[R.n]; else notes[R.n] = html;
      $$("[data-note-status]").forEach((el) => (el.textContent = "Saving…"));
      clearTimeout(saveTimer);
      saveTimer = setTimeout(() => $$("[data-note-status]").forEach((el) => (el.textContent = empty ? "Note removed" : "Saved")), 600);
      $$("[data-note]").forEach((other) => { if (other !== ed) other.innerHTML = html; });
      $$("[data-note-preview]").forEach((el) => { el.textContent = empty ? "Write a note" : plain(html); el.classList.toggle("empty", empty); });
      $$("[data-v]").forEach((b) => +b.dataset.v === R.n && b.classList.toggle("noted", !empty));
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") { closePops(); document.activeElement?.blur(); R.listeners.forEach((fn) => fn(R.n, false, "escape")); return; }
      if (e.target.closest("[contenteditable], input, textarea") || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === "j" || e.key === "ArrowRight") { e.preventDefault(); R.next(); }
      else if (e.key === "k" || e.key === "ArrowLeft") { e.preventDefault(); R.prev(); }
      else if (e.key === "b") { kept.has(R.n) ? kept.delete(R.n) : kept.add(R.n); render(); }
      else if (e.key === "n" || (e.key === "Enter" && e.target === document.body)) { const ed = $$("[data-note]").find((el) => el.offsetParent); if (ed) { e.preventDefault(); ed.focus(); R.listeners.forEach((fn) => fn(R.n, false, "write")); } }
    });

    $$("[data-swipe]").forEach((el) => {
      let x0, y0;
      el.addEventListener("touchstart", (e) => { x0 = e.touches[0].clientX; y0 = e.touches[0].clientY; }, { passive: true });
      el.addEventListener("touchend", (e) => {
        const dx = e.changedTouches[0].clientX - x0, dy = e.changedTouches[0].clientY - y0;
        if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) dx < 0 ? R.next() : R.prev();
      });
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    const m = location.hash.match(/^#v(\d+)$/);
    R.n = m ? Math.max(1, Math.min(verses.length, +m[1])) : 3;
    build();
    wire();
    render(false);
  });
})();
