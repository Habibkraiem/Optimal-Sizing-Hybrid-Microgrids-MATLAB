"""Figures 10.2 and 10.3 from results/ch10_weights.mat (Python version of the MATLAB plots)."""
import sys, scipy.io as sio, numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
d = sio.loadmat(sys.argv[1]); out = sys.argv[2]
w1 = np.ravel(d["w1"]); Vn = d["Vn"]; V0n = np.ravel(d["V0n"]); Lj = d["Lj"]; L0 = np.ravel(d["L0"])
col = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100"]; mk = ["^", "s", "D", "v"]; base = "#525250"
lab = ["A  (w$_{NPC}$ = 1/3)", "B  (w$_{NPC}$ = 0.20)", "C  (w$_{NPC}$ = 0.10)", "D  (w$_{NPC}$ = 0)"]
plt.rcParams.update({"font.size": 9, "axes.spines.top": False, "axes.spines.right": False})
b = np.arange(1, 34)
fig, ax = plt.subplots(figsize=(6.3, 3.6), dpi=300)
ax.plot(b, V0n, "--o", color=base, ms=3.5, mfc="white", lw=1, label="Base case (no DER)")
for j in range(4):
    ax.plot(b, Vn[:, j], "-" + mk[j], color=col[j], ms=3.5, lw=1.2, label=lab[j])
ax.axhline(0.95, ls=":", color="#888", lw=0.8)
ax.set_xlim(1, 33); ax.set_xticks([1, 5, 10, 15, 18, 22, 25, 30, 33]); ax.grid(alpha=0.3)
ax.set_xlabel("Bus"); ax.set_ylabel("Voltage (p.u.)")
ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.17), ncol=3, frameon=False, fontsize=8)
fig.tight_layout(); fig.savefig(out + "/fig10_2.png", dpi=300, facecolor="white")
fig, ax = plt.subplots(figsize=(6.3, 3.4), dpi=300)
h = np.arange(24)
ax.plot(h, L0, "-", color="black", lw=2.2, alpha=0.35, label="Base case (no DER)")
sty = ["-", "--", "-.", ":"]
for j in range(4):
    ax.plot(h, Lj[:, j], sty[j], marker=mk[j], markevery=3, ms=4, color=col[j], lw=1.4, label=lab[j])
ax.set_xlim(0, 23); ax.set_ylim(0, None); ax.grid(alpha=0.3)
ax.set_xlabel("Hour of the day"); ax.set_ylabel("Active power losses (kW)")
ax.legend(loc="upper left", frameon=False, fontsize=8)
fig.tight_layout(); fig.savefig(out + "/fig10_3.png", dpi=300, facecolor="white")
