// The page. A canvas you click, drawn from one string the realm hands out.
import * as e from "./engine.js";
import { NETWORKS, qevalString, wallet, gnokeyCommand } from "./chain.js";
import * as onboarding from "./onboarding.js";
import * as gnosession from "./session.js";

const $ = (id) => document.getElementById(id);
const state = { net: NETWORKS.mainnet, netName: "mainnet", account: null, color: 5,
  cells: e.decode(e.empty()), session: null, grant: null };

const PX = 16;
const ctx = $("canvas").getContext("2d");

function draw() {
  for (let y = 0; y < e.SIZE; y++)
    for (let x = 0; x < e.SIZE; x++) {
      ctx.fillStyle = e.COLORS[e.at(state.cells, x, y)];
      ctx.fillRect(x * PX, y * PX, PX, PX);
    }
  // A faint grid, so an empty canvas reads as "nothing painted yet" rather than
  // as a page that failed to load. The realm's own SVG has no grid: it is a
  // picture, this is an editor.
  ctx.strokeStyle = "rgba(0,0,0,.06)";
  ctx.lineWidth = 1;
  for (let i = 0; i <= e.SIZE; i++) {
    ctx.beginPath(); ctx.moveTo(i * PX + .5, 0); ctx.lineTo(i * PX + .5, e.SIZE * PX); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, i * PX + .5); ctx.lineTo(e.SIZE * PX, i * PX + .5); ctx.stroke();
  }
}

function drawPalette() {
  $("palette").innerHTML = e.COLORS.map((hex, i) =>
    `<button type="button" data-color="${i}" class="${i === state.color ? "on" : ""}" ` +
    `style="background:${hex}" aria-label="colour ${i}, ${hex}"></button>`).join("");
  $("chosen").textContent = `colour ${state.color} · ${e.COLORS[state.color]}`;
  $("cmd").textContent = gnokeyCommand(state.net, "Paint", ["<x>", "<y>", state.color]);
}

const cellAt = (ev) => {
  const r = $("canvas").getBoundingClientRect();
  return {
    x: Math.floor(((ev.clientX - r.left) / r.width) * e.SIZE),
    y: Math.floor(((ev.clientY - r.top) / r.height) * e.SIZE),
  };
};

const say = (msg, cls = "") => { const s = $("status"); s.textContent = msg; s.className = `status ${cls}`; };

async function refresh() {
  try {
    const cells = e.decode(await qevalString(state.net, "Canvas()"));
    // A canvas that does not decode is a bug worth seeing, not one to paper
    // over by drawing something approximate.
    if (!cells) throw new Error("the realm returned a canvas this page cannot read");
    state.cells = cells;
    draw();
    say(`${e.painted(cells)} cells painted on ${state.netName}`, "live");
    renderFeed(await qevalString(state.net, "Feed()"));
  } catch (err) {
    // Not deployed on this network yet is a normal state for a repository whose
    // whole subject is the deploy story. An empty panel reads as "still
    // loading" forever, so say what happened instead.
    $("feed").innerHTML = `<p class="fine">Nothing to read here: the realm is not deployed on this network yet, or the node did not answer.</p>`;
    say(`${state.netName}: ${err.message}`, "bad");
  }
}

function renderFeed(text) {
  const rows = text.split("\n").filter(Boolean).map((r) => r.split("\t"));
  $("feed").innerHTML = rows.length
    ? rows.map(([who, x, y, c]) =>
        `<div><span style="color:${e.COLORS[Number(c)]}">■</span> ${who.slice(0, 8)}… → ${x},${y}</div>`).join("")
    : `<p class="fine">Nothing painted here yet.</p>`;
}

$("canvas").addEventListener("mousemove", (ev) => {
  const { x, y } = cellAt(ev);
  $("cursor").textContent = `${x},${y} · colour ${e.at(state.cells, x, y)}`;
});

$("canvas").addEventListener("click", async (ev) => {
  const { x, y } = cellAt(ev);
  if (!state.account) { say("connect a wallet to paint, or paste the command below", "bad"); return; }
  try {
    say("signing…");
    await send("Paint", [x, y, state.color]);
    // Paint locally straight away so the click feels immediate, then let the
    // chain correct it. The optimistic cell is never trusted: refresh
    // overwrites the whole canvas with what the realm actually holds.
    state.cells[y * e.SIZE + x] = state.color;
    draw();
    say("sent — waiting for the block", "live");
    setTimeout(refresh, 1500);
  } catch (err) { say(err.message, "bad"); }
});

document.addEventListener("click", async (ev) => {
  const t = ev.target;
  if (t.dataset.color !== undefined) { state.color = Number(t.dataset.color); return drawPalette(); }
  if (t.id === "reload") return refresh();
  if (t.id === "share") { await navigator.clipboard.writeText(location.href); say("link copied", "live"); }
  if (t.id === "connect") {
    try { state.account = await wallet.connect(); say(`connected ${state.account.slice(0, 10)}…`, "live"); }
    catch (err) { say(err.message, "bad"); }
  }
});

$("network").addEventListener("change", (ev) => {
  state.netName = ev.target.value;
  state.net = NETWORKS[state.netName];
  $("link-realm").href = `https://gno.land/${state.net.realm.replace("gno.land/", "")}`;
  drawPalette();
  refresh();
});


// The session panel. When a session is granted, the app signs here; otherwise it
// falls back to the wallet. Same caller either way: the chain sees the master.
const sessionPanel = onboarding.mount({
  el: $("session"),
  net: () => state.net,
  getAccount: () => state.account,
  setAccount: (addr) => {
    // Named, not connected: enough to read a grant and to be the caller in one,
    // and it never lets this page sign anything the session cannot.
    state.account = addr;
    say(`playing as ${addr.slice(0, 10)}…`, "live");
  },
  keyName: "YOURKEY",
  onChange: ({ session, grant }) => { state.session = session; state.grant = grant; },
});

/** send signs with the session when there is one, and with the wallet when not. */
async function send(fn, args) {
  if (state.grant) {
    return gnosession.call({
      rpcUrl: state.net.rpc, chainId: state.net.chainId,
      session: state.session, grant: state.grant, func: fn, args,
    });
  }
  return wallet.call(state.net, state.account, fn, args);
}

drawPalette();
draw();
refresh();
setInterval(refresh, 8000);
