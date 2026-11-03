/**
 * Ghost wardrobe (PREVIEW): pixel-art cosmetic layers for the 8-bit spy ghost,
 * drawn procedurally on a 32x32 grid. Purchases and the 1/1000 mint are
 * SIMULATED in this branch: no wallet calls, no token transfers, no contract.
 * Behind VITE_GHOST_WARDROBE === "1" (off by default).
 */
export const ghostWardrobeEnabled = () => false;

export type Category = "hat" | "shades" | "skin" | "aura" | "trail" | "prop";
export type Rarity = "common" | "rare" | "epic" | "legendary";
export type Cosmetic = { id: string; name: string; cat: Category; rarity: Rarity; c: string[]; kind: string; via?: "quest" | "buy" };
/** Quest-only items cannot be bought; buy-only cannot be earned; default is either. */
export const QUEST_ONLY: Record<string, string> = { "shades-red": "Forge 7-day streak", "aura-base": "Bridge quest (future)", "trail-code": "Collect 5 medals", "skin-glitch": "Find 3 glitch ghosts" };
export const BUY_ONLY = ["crown", "prop-duck", "party"];
export const QUESTS = [{ id: "streak7", name: "Claim 7 days in a row", reward: "shades-red" }];

/** Placeholder preview prices in YOUCOG; final prices are Andy's call. */
export const RARITY_PRICE: Record<Rarity, number> = { common: 100, rare: 500, epic: 2000, legendary: 10000 };
export const CATEGORIES: { id: Category; label: string }[] = [
  { id: "hat", label: "Hats" }, { id: "shades", label: "Shades" }, { id: "skin", label: "Sheets" },
  { id: "aura", label: "Auras" }, { id: "trail", label: "Trails" }, { id: "prop", label: "Props" },
];

const C = (id: string, name: string, cat: Category, rarity: Rarity, kind: string, ...c: string[]): Cosmetic => ({ id, name, cat, rarity, kind, c });
export const COSMETICS: Cosmetic[] = [
  C("fedora-white", "Spy Fedora", "hat", "common", "fedora", "#f4f4f4", "#1b1b2f"),
  C("fedora-red", "Red Fedora", "hat", "common", "fedora", "#d7263d", "#1b1b2f"),
  C("fedora-gold", "Gold Fedora", "hat", "epic", "fedora", "#f5b301", "#7a4b00"),
  C("beanie", "Beanie", "hat", "common", "beanie", "#3a86ff", "#ffffff"),
  C("tophat", "Top Hat", "hat", "rare", "tophat", "#151515", "#d7263d"),
  C("crown", "Pixel Crown", "hat", "legendary", "crown", "#f5b301", "#d7263d"),
  C("cap", "Backwards Cap", "hat", "common", "cap", "#2ec4b6", "#0b3d3a"),
  C("propeller", "Propeller Cap", "hat", "rare", "propeller", "#ff9f1c", "#3a86ff"),
  C("party", "Party Cone", "hat", "common", "party", "#ff5ac8", "#f5b301"),
  C("shades-black", "Spy Shades", "shades", "common", "shades", "#0d0d0d", "#4a4a4a"),
  C("shades-red", "Laser Visor", "shades", "rare", "visor", "#ff2a2a", "#ffb3b3"),
  C("shades-blue", "Ice Visor", "shades", "rare", "visor", "#3a86ff", "#bde0ff"),
  C("heart", "Heart Shades", "shades", "common", "heart", "#ff3d7f", "#ffd1e0"),
  C("3d", "3D Glasses", "shades", "common", "3d", "#ff2a2a", "#2ec4ff"),
  C("monocle", "Monocle", "shades", "epic", "monocle", "#f5b301", "#cfe8ff"),
  C("pixel", "Deal-With-It", "shades", "legendary", "pixel", "#0d0d0d", "#ffffff"),
  C("skin-classic", "Classic Sheet", "skin", "common", "skin", "#ffffff", "#c9d1e6"),
  C("skin-mint", "Mint Sheet", "skin", "common", "skin", "#c8f7dc", "#7fd1a8"),
  C("skin-lilac", "Lilac Sheet", "skin", "rare", "skin", "#e3d0ff", "#a98be0"),
  C("skin-trench", "Trench Coat", "skin", "epic", "trench", "#c49a6c", "#7a5533"),
  C("skin-tux", "Tuxedo", "skin", "rare", "tux", "#1b1b2f", "#ffffff"),
  C("skin-glitch", "Glitch Sheet", "skin", "legendary", "glitch", "#ffffff", "#2ec4ff", "#ff2a6d"),
  C("aura-none-blue", "Blue Glow", "aura", "common", "glow", "#3a86ff"),
  C("aura-gold", "Gold Glow", "aura", "rare", "glow", "#f5b301"),
  C("aura-fire", "Fire Ring", "aura", "epic", "ring", "#ff5a1f", "#f5b301"),
  C("aura-sparkle", "Sparkles", "aura", "rare", "sparkle", "#ffffff", "#f5b301"),
  C("aura-base", "Base Halo", "aura", "legendary", "halo", "#0052ff", "#9cc0ff"),
  C("trail-mist", "Mist Trail", "trail", "common", "mist", "#c9d1e6"),
  C("trail-rainbow", "Rainbow Trail", "trail", "epic", "rainbow", "#ff2a2a", "#ff9f1c", "#f5b301", "#2ec4b6", "#3a86ff"),
  C("trail-coins", "Coin Trail", "trail", "rare", "coins", "#f5b301", "#7a4b00"),
  C("trail-code", "Code Trail", "trail", "rare", "code", "#39ff14"),
  C("trail-flame", "Flame Trail", "trail", "legendary", "flame", "#ff5a1f", "#f5b301"),
  C("prop-briefcase", "Briefcase", "prop", "common", "briefcase", "#7a5533", "#f5b301"),
  C("prop-coffee", "Coffee", "prop", "common", "coffee", "#ffffff", "#6b3e1e"),
  C("prop-balloon", "Balloon", "prop", "common", "balloon", "#ff3d7f", "#ffffff"),
  C("prop-laptop", "Laptop", "prop", "rare", "laptop", "#9aa4bf", "#39ff14"),
  C("prop-wand", "Magic Wand", "prop", "epic", "wand", "#151515", "#f5b301"),
  C("prop-duck", "Rubber Duck", "prop", "rare", "duck", "#ffd60a", "#ff9f1c"),
];
export const byId = (id?: string | null) => COSMETICS.find((x) => x.id === id);
export type Outfit = Partial<Record<Category, string>>;
export const DEFAULT_OUTFIT: Outfit = { hat: "fedora-white", shades: "shades-black", skin: "skin-classic" };
export const DEFAULT_OWNED = ["fedora-white", "shades-black", "skin-classic"];

/** Combinations if each slot may also be empty. */
export const comboCount = () =>
  CATEGORIES.reduce((n, k) => n * (COSMETICS.filter((x) => x.cat === k.id).length + 1), 1);

type P = (x: number, y: number, w: number, h: number, col: string) => void;

function body(p: P, ck: Cosmetic | undefined, t: number) {
  const [f, s, g] = ck?.c ?? ["#ffffff", "#c9d1e6"];
  const o = "#1b1b2f";
  // sheet silhouette: head dome rows 10-14, body 14-26, wavy hem 26-28
  const rows: [number, number][] = [[13, 6], [11, 10], [10, 12], [9, 14], [9, 14]];
  rows.forEach(([x, w], i) => { p(x - 1, 10 + i, w + 2, 1, o); p(x, 10 + i, w, 1, f); });
  for (let y = 15; y < 27; y++) { p(8, y, 16, 1, o); p(9, y, 14, 1, f); p(19, y, 4, 1, s); }
  const ph = Math.floor(t / 250) % 2;
  for (let i = 0; i < 4; i++) { p(9 + i * 4 + ph, 27, 2, 1, f); p(9 + i * 4 + ph, 28, 2, 1, o); }
  p(8, 9 + 18, 1, 1, o); p(23, 27, 1, 1, o);
  if (ck?.kind === "trench") { p(9, 19, 14, 8, f); p(15, 19, 2, 8, s); p(9, 21, 14, 1, s); p(12, 23, 1, 1, o); p(19, 23, 1, 1, o); }
  if (ck?.kind === "tux") { p(9, 18, 14, 9, f); p(14, 18, 4, 9, s); p(15, 18, 2, 1, "#d7263d"); p(15, 20, 2, 1, o); p(15, 22, 2, 1, o); }
  if (ck?.kind === "glitch" && g) { const k = Math.floor(t / 120) % 4; p(9 + k, 16 + k * 2, 6, 1, s); p(14 - k, 22 - k, 7, 1, g); }
}

function hat(p: P, ck?: Cosmetic) {
  if (!ck) return;
  const [a, b] = ck.c, o = "#1b1b2f";
  switch (ck.kind) {
    case "fedora": p(7, 10, 18, 2, o); p(8, 10, 16, 1, a); p(11, 5, 10, 5, o); p(12, 5, 8, 4, a); p(12, 8, 8, 1, b); p(15, 5, 2, 1, b); break;
    case "beanie": p(10, 6, 12, 5, a); p(10, 9, 12, 2, b); p(15, 4, 2, 2, b); break;
    case "tophat": p(8, 10, 16, 1, a); p(11, 2, 10, 8, a); p(11, 8, 10, 1, b); break;
    case "crown": p(10, 6, 12, 4, a); p(10, 4, 2, 2, a); p(15, 3, 2, 3, a); p(20, 4, 2, 2, a); p(13, 7, 2, 2, b); p(18, 7, 2, 2, b); break;
    case "cap": p(10, 7, 12, 4, a); p(20, 9, 6, 2, b); p(15, 6, 2, 1, b); break;
    case "propeller": p(10, 7, 12, 4, a); p(15, 4, 2, 3, o); p(11, 3, 10, 1, b); break;
    case "party": p(14, 3, 4, 2, a); p(13, 5, 6, 2, b); p(12, 7, 8, 3, a); p(15, 1, 2, 2, b); break;
  }
}
function shades(p: P, ck: Cosmetic | undefined, t: number) {
  if (!ck) return;
  const [a, b] = ck.c;
  switch (ck.kind) {
    case "shades": p(10, 13, 12, 1, a); p(10, 14, 5, 3, a); p(17, 14, 5, 3, a); p(11, 14, 1, 1, b); p(18, 14, 1, 1, b); break;
    case "visor": p(9, 13, 14, 4, a); p(10 + (Math.floor(t / 90) % 12), 14, 2, 1, b); break;
    case "heart": [11, 18].forEach((x) => { p(x, 13, 1, 1, a); p(x + 2, 13, 1, 1, a); p(x - 1, 14, 5, 2, a); p(x, 16, 3, 1, a); p(x + 1, 17, 1, 1, a); p(x, 14, 1, 1, b); }); break;
    case "3d": p(10, 13, 12, 1, "#ffffff"); p(10, 14, 5, 3, a); p(17, 14, 5, 3, b); break;
    case "monocle": p(17, 13, 5, 5, a); p(18, 14, 3, 3, b); p(21, 18, 1, 6, a); p(12, 15, 3, 1, "#1b1b2f"); break;
    case "pixel": p(9, 13, 14, 1, a); for (let i = 0; i < 2; i++) { p(10 + i * 7, 14, 5, 2, a); p(10 + i * 7, 14, 1, 1, b); p(12 + i * 7, 15, 1, 1, b); } break;
  }
}
function aura(p: P, ck: Cosmetic | undefined, t: number) {
  if (!ck) return;
  const [a, b] = ck.c, ph = Math.floor(t / 200) % 2;
  switch (ck.kind) {
    case "glow": for (let y = 7; y < 30; y += 2) { p(5 + ph, y, 1, 1, a); p(26 - ph, y, 1, 1, a); } for (let x = 7; x < 26; x += 2) p(x + ph, 30, 1, 1, a); break;
    case "ring": for (let i = 0; i < 16; i++) { const an = (i / 16) * Math.PI * 2 + t / 600; p(Math.round(16 + Math.cos(an) * 13), Math.round(18 + Math.sin(an) * 13), 1, 1, i % 2 ? a : b); } break;
    case "sparkle": [[4, 8], [27, 12], [5, 24], [26, 26], [16, 1]].forEach(([x, y], i) => { if ((Math.floor(t / 180) + i) % 3) { p(x, y, 1, 1, a); p(x - 1, y, 1, 1, b); p(x + 1, y, 1, 1, b); p(x, y - 1, 1, 1, b); p(x, y + 1, 1, 1, b); } }); break;
    case "halo": p(11, 1 + ph, 10, 1, a); p(10, 2 + ph, 1, 1, a); p(21, 2 + ph, 1, 1, a); p(11, 3 + ph, 10, 1, b); break;
  }
}
function trail(p: P, ck: Cosmetic | undefined, t: number) {
  if (!ck) return;
  const sh = Math.floor(t / 150) % 3;
  switch (ck.kind) {
    case "mist": for (let i = 0; i < 3; i++) p(1 + i * 2 + (i + sh) % 2, 20 + i * 3, 4 - i, 1, ck.c[0]); break;
    case "rainbow": ck.c.forEach((col, i) => p(0, 17 + i, 8 - ((i + sh) % 2), 1, col)); break;
    case "coins": for (let i = 0; i < 3; i++) { const x = 1 + i * 2, y = 14 + ((i * 5 + sh * 3) % 12); p(x, y, 2, 2, ck.c[0]); p(x + 1, y + 1, 1, 1, ck.c[1]); } break;
    case "code": for (let i = 0; i < 4; i++) p(1 + (i % 2) * 3, 12 + ((i * 4 + sh * 2) % 16), 1, 2, ck.c[0]); break;
    case "flame": for (let i = 0; i < 4; i++) { p(0 + i, 22 - i * 2 - (sh % 2), 2, 2, ck.c[i % 2]); } break;
  }
}
function prop(p: P, ck?: Cosmetic) {
  if (!ck) return;
  const [a, b] = ck.c, o = "#1b1b2f";
  switch (ck.kind) {
    case "briefcase": p(23, 22, 7, 5, a); p(25, 21, 3, 1, o); p(26, 24, 1, 1, b); break;
    case "coffee": p(24, 20, 4, 6, a); p(24, 20, 4, 1, b); p(28, 22, 1, 2, a); p(25, 18, 1, 1, "#c9d1e6"); p(26, 17, 1, 1, "#c9d1e6"); break;
    case "balloon": p(25, 3, 5, 6, a); p(26, 4, 1, 1, b); p(27, 9, 1, 12, o); break;
    case "laptop": p(23, 20, 8, 5, a); p(24, 21, 6, 3, o); p(25, 22, 3, 1, b); p(22, 25, 10, 1, a); break;
    case "wand": p(24, 16, 1, 10, a); p(23, 14, 3, 1, b); p(24, 13, 1, 3, b); break;
    case "duck": p(24, 22, 6, 4, a); p(27, 19, 3, 3, a); p(30, 20, 1, 1, b); p(28, 20, 1, 1, o); break;
  }
}

/** Draw the ghost + outfit at time t (ms). Grid is 32x32, scaled by px. */
export function drawGhost(ctx: CanvasRenderingContext2D, outfit: Outfit, t = 0, px = 6) {
  ctx.clearRect(0, 0, 32 * px, 32 * px);
  const bob = Math.round(Math.sin(t / 400));
  const p: P = (x, y, w, h, col) => { ctx.fillStyle = col; ctx.fillRect(x * px, (y + bob) * px, w * px, h * px); };
  const g = (k: Category) => byId(outfit[k]);
  aura(p, g("aura"), t);
  trail(p, g("trail"), t);
  body(p, g("skin"), t);
  if (!g("shades")) { p(12, 14, 2, 2, "#1b1b2f"); p(18, 14, 2, 2, "#1b1b2f"); }
  shades(p, g("shades"), t);
  hat(p, g("hat"));
  prop(p, g("prop"));
}
export { body, hat, shades, aura, trail, prop };
