"""Figure 10.1 - single-line diagram of the IEEE 33-bus feeder with the chosen buses.
Usage: python draw_fig10_1.py out.png '<json of markers>'
markers: list of {"bus": int, "label": str, "color": hex}
"""
import json, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

pos = {}
for b in range(1, 19):                      # main feeder
    pos[b] = (b - 1, 0.0)
for k, b in enumerate(range(19, 23)):       # lateral from bus 2
    pos[b] = (1 + k + 1, 2.6)
for k, b in enumerate(range(23, 26)):       # lateral from bus 3
    pos[b] = (2 + k + 1, 1.3)
for k, b in enumerate(range(26, 34)):       # lateral from bus 6
    pos[b] = (5 + k + 1, -1.6)
edges = [(b, b + 1) for b in range(1, 18)] + [(2, 19), (19, 20), (20, 21), (21, 22),
         (3, 23), (23, 24), (24, 25), (6, 26)] + [(b, b + 1) for b in range(26, 33)]

def main(out, markers):
    fig, ax = plt.subplots(figsize=(10, 3.9), dpi=300)
    for a, b in edges:
        (x1, y1), (x2, y2) = pos[a], pos[b]
        if y1 != y2:                       # lateral: go down/up, then across
            ax.plot([x1, x1, x2], [y1, y2, y2], color="#555", lw=1.2, zorder=1)
        else:
            ax.plot([x1, x2], [y1, y2], color="#555", lw=1.2, zorder=1)
    for b, (x, y) in pos.items():
        ax.plot(x, y, "o", ms=5.5, color="white", mec="#333", mew=1, zorder=2)
        ax.text(x, y + 0.28, str(b), ha="center", va="bottom", fontsize=7, color="#333")
    # substation
    x, y = pos[1]
    ax.add_patch(plt.Rectangle((x - 0.9, y - 0.35), 0.6, 0.7, fc="#eee", ec="#333", lw=1))
    ax.text(x - 0.6, y - 0.6, "Substation", ha="center", va="top", fontsize=7)
    # markers (stack several on one bus)
    count = {}
    for m in markers:
        b = m["bus"]; k = count.get(b, 0); count[b] = k + 1
        x, y = pos[b]
        yy = y - 0.45 - 0.42 * k
        ax.text(x, yy, m["label"], ha="center", va="top", fontsize=7, color="black",
                bbox=dict(boxstyle="round,pad=0.25", fc="white", ec=m["color"], lw=1.4), zorder=3)
        ax.plot(x, y, "o", ms=7, color=m["color"], zorder=2.5)
    ax.set_xlim(-1.2, 17.6); ax.set_ylim(-3.2, 3.3)
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(out, dpi=300, bbox_inches="tight", facecolor="white")

if __name__ == "__main__":
    main(sys.argv[1], json.loads(sys.argv[2]))
