import { useEffect, useMemo, useState } from "react";

const BACKS = { dark: "#262a33", light: "#d8dde6", check: "check" };

export default function App() {
  const [items, setItems] = useState([]);
  const [folder, setFolder] = useState("all");
  const [query, setQuery] = useState("");
  const [usage, setUsage] = useState("all");
  const [scale, setScale] = useState(1 / 3);
  const [fit, setFit] = useState(false);
  const [back, setBack] = useState("dark");
  const [sort, setSort] = useState("name");
  const [open, setOpen] = useState(null);

  useEffect(() => {
    fetch("index.json").then((r) => r.json()).then(setItems);
  }, []);

  const folders = useMemo(() => {
    const m = new Map();
    items.forEach((i) => m.set(i.folder, (m.get(i.folder) || 0) + 1));
    return [...m.entries()].sort();
  }, [items]);

  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list = items.filter(
      (i) =>
        (folder === "all" || i.folder === folder) &&
        (usage === "all" || (usage === "used") === i.usedIn.length > 0) &&
        (!q || i.name.toLowerCase().includes(q) || i.folder.toLowerCase().includes(q) || i.usedIn.some((u) => u.toLowerCase().includes(q)))
    );
    const by = { name: (a, b) => a.name.localeCompare(b.name), size: (a, b) => a.w * a.h - b.w * b.h, folder: (a, b) => a.folder.localeCompare(b.folder) || a.name.localeCompare(b.name) };
    return list.sort(by[sort]);
  }, [items, folder, query, usage, sort]);

  const unused = items.filter((i) => !i.usedIn.length).length;

  return (
    <div className="app">
      <aside>
        <h1>Cat Platformer<small>assety gry</small></h1>
        <p className="stat">
          {items.length} plików · <b className="ok">{items.length - unused} użytych</b> · <b className="no">{unused} nieużytych</b>
        </p>
        <nav>
          <button className={folder === "all" ? "on" : ""} onClick={() => setFolder("all")}>
            wszystko <span>{items.length}</span>
          </button>
          {folders.map(([f, n]) => (
            <button key={f} className={folder === f ? "on" : ""} onClick={() => setFolder(f)}>
              {f.replace("game/", "")} <span>{n}</span>
            </button>
          ))}
        </nav>
      </aside>
      <main>
        <header>
          <input placeholder="szukaj: nazwa, folder, scena…" value={query} onChange={(e) => setQuery(e.target.value)} autoFocus />
          <select value={usage} onChange={(e) => setUsage(e.target.value)}>
            <option value="all">użyte i nieużyte</option>
            <option value="used">tylko użyte</option>
            <option value="unused">tylko nieużyte</option>
          </select>
          <select value={sort} onChange={(e) => setSort(e.target.value)}>
            <option value="name">nazwa</option>
            <option value="size">rozmiar</option>
            <option value="folder">folder</option>
          </select>
          <label>
            skala
            <input type="range" min="0.1" max="1.5" step="0.05" value={scale} onChange={(e) => setScale(+e.target.value)} />
            <span>{scale === 1 / 3 ? "1/3 (w grze)" : "×" + scale.toFixed(2)}</span>
          </label>
          <button onClick={() => setScale(1 / 3)}>1/3</button>
          <button onClick={() => setScale(1)}>1:1</button>
          <label className="chk"><input type="checkbox" checked={fit} onChange={(e) => setFit(e.target.checked)} /> duże dopasuj</label>
          <select value={back} onChange={(e) => setBack(e.target.value)}>
            <option value="dark">ciemne tło</option>
            <option value="light">jasne tło</option>
            <option value="check">szachownica</option>
          </select>
          <span className="count">{shown.length} / {items.length}</span>
        </header>
        <section className="grid">
          {shown.map((i) => {
            const k = fit && Math.max(i.w, i.h) * scale > 360 ? 360 / Math.max(i.w, i.h) : scale;
            return (
              <figure key={i.res} onClick={() => setOpen(i)} title={i.res}>
                <div className={"thumb " + (back === "check" ? "check" : "")} style={{ background: back === "check" ? undefined : BACKS[back] }}>
                  <img src={i.src} width={Math.max(1, Math.round(i.w * k))} height={Math.max(1, Math.round(i.h * k))} alt={i.name} loading="lazy" />
                </div>
                <figcaption className={i.usedIn.length ? "used" : "unused"}>
                  <b>{i.name}</b>
                  <span>{i.w}×{i.h}</span>
                </figcaption>
              </figure>
            );
          })}
        </section>
      </main>
      {open && <Detail item={open} back={back} onClose={() => setOpen(null)} />}
    </div>
  );
}

function Detail({ item, back, onClose }) {
  const [copied, setCopied] = useState("");
  useEffect(() => {
    const h = (e) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [onClose]);
  const copy = (text, what) => navigator.clipboard.writeText(text).then(() => { setCopied(what); setTimeout(() => setCopied(""), 1200); });
  return (
    <div className="overlay" onClick={onClose}>
      <div className="detail" onClick={(e) => e.stopPropagation()}>
        <div className={"view " + (back === "check" ? "check" : "")} style={{ background: back === "check" ? undefined : BACKS[back] }}>
          <img src={item.src} alt={item.name} style={{ imageRendering: "pixelated", maxWidth: "100%", maxHeight: "70vh" }} />
        </div>
        <div className="info">
          <h2>{item.name}</h2>
          <dl>
            <dt>ścieżka</dt><dd><code>{item.res}</code> <button onClick={() => copy(item.res, "res")}>{copied === "res" ? "skopiowano" : "kopiuj"}</button></dd>
            <dt>rozmiar</dt><dd>{item.w}×{item.h} px (w grze ≈ {Math.round(item.w / 3)}×{Math.round(item.h / 3)} px) · {(item.bytes / 1024).toFixed(1)} KB</dd>
            <dt>folder</dt><dd>{item.folder}</dd>
            <dt>użycie</dt>
            <dd>
              {item.usedIn.length ? <ul>{item.usedIn.map((u) => <li key={u}><code>{u}</code></li>)}</ul> : <b className="no">nieużyty w żadnej scenie ani skrypcie</b>}
            </dd>
          </dl>
          <button onClick={onClose}>zamknij (Esc)</button>
        </div>
      </div>
    </div>
  );
}
