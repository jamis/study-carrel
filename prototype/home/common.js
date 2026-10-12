// Shared data and behavior for the home (focuses) prototypes.
//
//   window.FOCI               the sample foci, the current one first, then past ones newest first;
//                             each has its latest note and a few earlier ones (recent)
//   Home.date(d) / span(f)    "14 Sep 2026" / "Mar – Jun 2026"
//   [data-top]                replaced with the top bar (crumb "Focuses", ⋯ menu)
//   [data-switch]             replaced with the layout switcher tab
//   [data-pop-toggle=id]      opens/closes #id; clicking outside or Esc closes
//   "Make current" buttons (data-restore=id) move that focus to the top and re-render via Home.render()
(() => {
  const FOCI = [
    {
      id: 1, title: "What does it mean to be holy?", current: true,
      description: "Reading Isaiah slowly, asking what “holy” names: a quality, a distance, a calling? And whether it can be said of people at all.",
      started: "2026-09-14", ended: null, notes: 23, keeps: 4,
      works: ["Isaiah", "Leviticus", "Psalms"],
      last: { ref: "Isaiah 40:25", text: "To whom then will ye liken me, or shall I be equal? saith the Holy One." },
      latest: { ref: "Isaiah 40:25", when: "yesterday", text: "“To whom then will ye liken me?” The holy as the incomparable: not a higher rung but off the ladder." },
      recent: [{ ref: "Isaiah 40:18", text: "“To whom then will ye liken God?” Every likeness falls short; that’s the point." }, { ref: "Leviticus 19:2", text: "“Be ye holy: for I the Lord your God am holy.” Holiness asked of people after all, and the next verses are about parents, sabbaths and gleanings." }],
    },
    {
      id: 2, title: "What is solitude for?",
      description: "Thoreau at the pond, and whether being alone is a retreat from people or a way back to them.",
      started: "2026-06-02", ended: "2026-09-14", notes: 41, keeps: 7,
      works: ["Walden", "Self-Reliance"],
      last: { ref: "Walden: Solitude ¶12", text: "I never found the companion that was so companionable as solitude." },
      latest: { ref: "Walden: Solitude ¶12", when: "14 Sep", text: "He’s not lonely because he never stops paying attention. Solitude as attention without an audience." },
      recent: [{ ref: "Walden: Where I Lived ¶16", text: "He went to the woods to front only the essential facts. Solitude as subtraction." }, { ref: "Self-Reliance 3:2", text: "Emerson: the great man keeps the independence of solitude in the crowd." }],
    },
    {
      id: 3, title: "Where is God in grief?",
      description: null,
      started: "2026-03-20", ended: "2026-06-02", notes: 17, keeps: 2,
      works: ["Job", "Psalms", "Lamentations"],
      last: { ref: "Lamentations 3:22", text: "It is of the Lord’s mercies that we are not consumed, because his compassions fail not." },
      latest: { ref: "Lamentations 3:22", when: "1 Jun", text: "Mercy said from inside the ruin, not after it." },
      recent: [{ ref: "Job 2:13", text: "His friends sat with him seven days and said nothing. They were best before they spoke." }, { ref: "Psalm 22:1", text: "The cry of abandonment is itself addressed to God." }],
    },
    {
      id: 4, title: "How should I treat the stranger?",
      description: "Hospitality in the Law and in Ruth: who counts as a stranger, and what is owed them.",
      started: "2026-01-08", ended: "2026-03-20", notes: 12, keeps: 1,
      works: ["Ruth", "Leviticus", "Deuteronomy"],
      last: { ref: "Ruth 2:10", text: "Why have I found grace in thine eyes, … seeing I am a stranger?" },
      latest: { ref: "Ruth 2:10", when: "19 Mar", text: "Boaz goes beyond the gleaning law. The law is the floor, not the ceiling." },
      recent: [{ ref: "Leviticus 19:34", text: "Love the stranger “as thyself: for ye were strangers.” Memory as the ground of hospitality." }, { ref: "Ruth 1:16", text: "“Whither thou goest.” The stranger chooses in." }],
    },
    {
      id: 5, title: "Is trusting yourself a virtue?",
      description: null,
      started: "2025-11-02", ended: "2026-01-08", notes: 9, keeps: 0,
      works: ["Self-Reliance"],
      last: { ref: "Self-Reliance 5:3", text: "Trust thyself: every heart vibrates to that iron string." },
      latest: { ref: "Self-Reliance 7:1", when: "6 Jan", text: "Emerson’s “self” sounds less like ego than like conscience." },
      recent: [{ ref: "Self-Reliance 2:1", text: "“Whoso would be a man must be a nonconformist.”" }, { ref: "Self-Reliance 4:4", text: "Consistency as the hobgoblin: trusting yourself means trusting today’s self." }],
    },
    {
      id: 6, title: "What does the morning ask of me?",
      description: "Psalms of morning, and Thoreau’s “morning work.”",
      started: "2025-10-01", ended: "2025-11-02", notes: 3, keeps: 1,
      works: ["Psalms", "Walden"],
      last: { ref: "Psalm 5:3", text: "My voice shalt thou hear in the morning, O Lord." },
      latest: { ref: "Psalm 5:3", when: "30 Oct", text: "“Look up”: the morning prayer is mostly waiting." },
      recent: [{ ref: "Walden: Where I Lived ¶8", text: "“Every morning was a cheerful invitation.”" }],
    },
  ];
  window.FOCI = FOCI;

  const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const parse = (s) => { const [y, m, d] = s.split("-").map(Number); return { y, m: m - 1, d }; };
  const date = (s) => { const { y, m, d } = parse(s); return `${d} ${MONTHS[m]} ${y}`; };
  const month = (s) => { const { y, m } = parse(s); return `${MONTHS[m]} ${y}`; };
  const span = (f) => {
    if (!f.ended) return `since ${date(f.started)}`;
    const a = parse(f.started), b = parse(f.ended);
    return a.y === b.y ? `${MONTHS[a.m]} – ${MONTHS[b.m]} ${b.y}` : `${month(f.started)} – ${month(f.ended)}`;
  };
  const plural = (n, w) => `${n} ${w}${n === 1 ? "" : "s"}`;
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

  const Home = (window.Home = { date, month, span, plural, esc, render: () => {} });

  const READ = "../reader/e.html";
  Home.read = READ;

  const top = () => `
    <header class="top"><div class="nav"><div class="nav-in">
      <div class="crumbs">Focuses</div>
      <div class="menu">
        <button class="icon-btn" type="button" aria-label="Menu" data-pop-toggle="nav-menu">⋯</button>
        <div class="menu-panel" id="nav-menu">
          <a class="menu-item" href="${READ}">Continue reading</a>
          <a class="menu-item" href="#">New focus</a>
          <div class="menu-sep"></div>
          <a class="menu-item" href="#">Library</a>
          <a class="menu-item" href="#">All notes</a>
          <button class="menu-item" type="button">Recent places<kbd>h</kbd></button>
          <a class="menu-item" href="#">Search<kbd>/</kbd></a>
          <a class="menu-item" href="#">Random</a>
          <a class="menu-item" href="#">Kept</a>
          <a class="menu-item" href="#">Your Texts</a>
          <button class="menu-item" type="button" data-theme-toggle>Light / dark</button>
          <button class="menu-item" type="button">Sign out</button>
        </div>
      </div>
    </div></div></header>`;

  const switcher = () => {
    const here = location.pathname.split("/").pop();
    return `<nav class="switch" aria-label="Layouts">${["a", "b", "b1", "b2", "b3", "b4", "c", "d"]
      .map((k) => `<a href="${k}.html" class="${here === `${k}.html` ? "on" : ""}">${k.toUpperCase()}</a>`).join("")}
      <a href="index.html" title="All layouts">≡</a></nav>`;
  };

  // A past focus brought back becomes current; the old current one is archived today.
  Home.restore = (id) => {
    const f = FOCI.find((x) => x.id === id), cur = FOCI.find((x) => x.current);
    if (!f || f === cur) return;
    cur.current = false; cur.ended = new Date().toISOString().slice(0, 10);
    f.current = true; f.ended = null; f.started = cur.ended;
    FOCI.splice(FOCI.indexOf(f), 1); FOCI.splice(FOCI.indexOf(cur), 1);
    FOCI.unshift(f, cur);
    Home.render();
  };

  const theme = () => {
    const root = document.documentElement;
    const dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
    root.dataset.theme = dark ? "light" : "dark";
    try { localStorage.setItem("home-theme", root.dataset.theme); } catch {}
  };
  try { const t = localStorage.getItem("home-theme"); if (t) document.documentElement.dataset.theme = t; } catch {}

  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("[data-top]").forEach((el) => (el.outerHTML = top()));
    document.querySelectorAll("[data-switch]").forEach((el) => (el.outerHTML = switcher()));
    Home.render();
  });

  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-pop-toggle]");
    const restore = e.target.closest("[data-restore]");
    if (e.target.closest("[data-theme-toggle]")) theme();
    if (restore) { e.preventDefault(); Home.restore(Number(restore.dataset.restore)); }
    document.querySelectorAll(".menu-panel.open, .pop.open").forEach((p) => {
      if (!(t && t.dataset.popToggle === p.id) && !p.contains(e.target)) p.classList.remove("open");
    });
    if (t) document.getElementById(t.dataset.popToggle)?.classList.toggle("open");
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") document.querySelectorAll(".menu-panel.open, .pop.open").forEach((p) => p.classList.remove("open"));
  });
})();
