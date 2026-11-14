# Asset browser

React (Vite) viewer for every PNG in `../assets/game`: folders, search, used / unused (is it referenced by any scene or script),
scale (1/3 = size in the game), backgrounds, details with the `res://` path and the files that use it.

    cd asset-browser
    npm install
    npm run dev        # http://localhost:5174 (regenerates public/index.json first)

`public/game` is a symlink to `../assets/game`, created by `scripts/build-index.mjs`. The folder has a `.gdignore`, so Godot skips it.
