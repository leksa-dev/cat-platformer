// Builds public/index.json: every PNG under ../assets/game with its size and where the Godot project uses it
// (scenes/*.tscn, scripts/*.gd, scenes/*.gd). Also makes sure public/game links to the assets folder.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, "../..");
const assets = path.join(project, "assets/game");
const link = path.resolve(here, "../public/game");

if (!fs.existsSync(link)) fs.symlinkSync(path.relative(path.dirname(link), assets), link, "dir");

function walk(dir, ext, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, out);
    else if (ext.some((x) => e.name.endsWith(x))) out.push(p);
  }
  return out;
}

const sources = [...walk(path.join(project, "scenes"), [".tscn", ".gd", ".tres"]), ...walk(path.join(project, "scripts"), [".gd"])].map((f) => ({
  file: path.relative(project, f),
  text: fs.readFileSync(f, "utf8"),
}));

const items = walk(assets, [".png"]).sort().map((f) => {
  const buf = fs.readFileSync(f);
  const rel = path.relative(assets, f).split(path.sep).join("/");
  const res = "res://assets/game/" + rel;
  const used = sources.filter((s) => s.text.includes(res)).map((s) => s.file);
  return {
    name: path.basename(f, ".png"),
    folder: path.dirname(rel) === "." ? "game" : "game/" + path.dirname(rel),
    src: "game/" + rel,
    res,
    w: buf.readUInt32BE(16),
    h: buf.readUInt32BE(20),
    bytes: buf.length,
    usedIn: used,
  };
});

fs.writeFileSync(path.resolve(here, "../public/index.json"), JSON.stringify(items));
console.log(`${items.length} PNG, used: ${items.filter((i) => i.usedIn.length).length}`);
