import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The game's PNGs are served straight from the Godot project (public/game is a symlink to ../assets/game).
export default defineConfig({ plugins: [react()], server: { port: 5174, fs: { allow: [".."] } } });
