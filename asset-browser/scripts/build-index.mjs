// Builds public/index.json for the browser: every image / sound under ../assets with its kind, size and where it is used.
//   kind "sprite" = PNG under assets/game (what the game loads), "sheet" = any other image (source sheets, mock-ups, temp), "sound" = audio.
// "Used in" = the project files that mention it: scenes/*.tscn, scripts, scenes/*.gd (by res:// path; sounds also by the name passed to
// Game.sfx / the level's `music`), and for sheets the tools/ scripts that cut sprites out of them.
// Also makes sure public/assets links to the assets folder.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, "../..");
const assets = path.join(project, "assets");
const link = path.resolve(here, "../public/assets");
const old = path.resolve(here, "../public/game");

if (fs.existsSync(old)) fs.rmSync(old, { force: true });
if (!fs.existsSync(link)) fs.symlinkSync(path.relative(path.dirname(link), assets), link, "dir");

function walk(dir, ext, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, out);
    else if (ext.some((x) => e.name.toLowerCase().endsWith(x))) out.push(p);
  }
  return out;
}

const read = (files) => files.map((f) => ({ file: path.relative(project, f), text: fs.readFileSync(f, "utf8") }));
const gameSources = read([...walk(path.join(project, "scenes"), [".tscn", ".gd", ".tres"]), ...walk(path.join(project, "scripts"), [".gd"])]);
const toolSources = read(walk(path.join(project, "tools"), [".py", ".gd"]));

const IMG = [".png", ".jpg", ".jpeg", ".webp"];
const SND = [".wav", ".ogg", ".mp3"];

function size(buf, f) {
  if (f.toLowerCase().endsWith(".png")) return [buf.readUInt32BE(16), buf.readUInt32BE(20)];
  return [0, 0];
}

const items = [];
for (const f of walk(assets, [...IMG, ...SND]).sort()) {
  const rel = path.relative(assets, f).split(path.sep).join("/");
  if (rel.startsWith("i18n/")) continue;
  const res = "res://assets/" + rel;
  const buf = fs.readFileSync(f);
  const ext = path.extname(f).toLowerCase();
  const base = path.basename(f, ext);
  const isSound = SND.includes(ext);
  const kind = isSound ? "sound" : rel.startsWith("game/") ? "sprite" : "sheet";
  let used = gameSources.filter((s) => s.text.includes(res)).map((s) => s.file);
  if (isSound) {
    const key = base.replace(/^music_/, "");
    const quoted = `"${key}"`;
    used = gameSources.filter((s) => s.text.includes(res) || (base.startsWith("music_") ? s.text.includes(`music = ${quoted}`) || s.text.includes(`play_music(${quoted}`) : s.text.includes(`sfx(${quoted}`))).map((s) => s.file);
  }
  const cut = kind === "sheet" ? toolSources.filter((s) => s.text.includes("assets/" + rel) || s.text.includes(path.basename(f))).map((s) => s.file) : [];
  const [w, h] = isSound ? [0, 0] : size(buf, f);
  const dir = path.dirname(rel);
  items.push({
    name: base,
    ext: ext.slice(1),
    kind,
    folder: dir === "." ? "(korzeń assets)" : dir,
    src: "assets/" + rel,
    res,
    w,
    h,
    bytes: buf.length,
    usedIn: used,
    cutBy: cut,
  });
}

fs.writeFileSync(path.resolve(here, "../public/index.json"), JSON.stringify(items));
const by = (k) => items.filter((i) => i.kind === k);
for (const k of ["sprite", "sheet", "sound"]) console.log(`${k}: ${by(k).length}, used/cut: ${by(k).filter((i) => i.usedIn.length || i.cutBy.length).length}`);
