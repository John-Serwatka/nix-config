# Laptop Hardware Alignment (ROG Zephyrus G14 GA402RJ)

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax. Nothing below has been validated on the running system — see Status.

**Goal:** Bring `hosts/laptop` into line with what the machine actually is: an ASUS ROG Zephyrus G14 GA402RJ with a hardware MUX, a dGPU that never idles, no OpenCL, and no hibernation path on an S3-less platform.

**Stage 1 complete (2026-10-03).** Switched to generation 55 (nixpkgs `b4fd65b`, alongside a `flake.lock` bump) at 00:42, *after* the 00:26 boot — so the running kernel is still generation 54's and its cmdline carries no `resume=`. Next: reboot, then Stage 2.

## Status

| | |
|---|---|
| Config edits | **Done, committed** (`hosts/laptop/default.nix`, `modules/hardware/graphics.nix`) |
| `just fmt` | **Passes** (alejandra clean) |
| Evaluation | **Passes** — `drvPath` resolves, all assertions satisfied |
| `nix build` | **Done** |
| `nixos-rebuild switch` | **Done** — generation 55, 2026-10-03 00:42 |
| Reboot | **Not done since the switch** — booted generation is 54; `resume_offset` is in gen 55's `kernel-params` but not in `/proc/cmdline` |
| Anything validated on hardware | **No** |

## Live system changes already made (outside nix)

Run as root via a scratchpad script, on the real filesystem:

- Created top-level btrfs subvolume `@swap` on `1bdf2072-6197-4926-b038-f8daae630169` (alongside `@`, `@home`, `@nix`, `@log`).
- Mounted it at `/swap` with `subvol=@swap,noatime` — deliberately **no** `compress=`, since a swapfile is NODATACOW and cannot be compressed.
- Created `/swap/swapfile`, 16 GiB, via `btrfs filesystem mkswapfile --size 16g`.

> **Resolved 2026-10-03:** `/swap` and `/swap/swapfile` now come from the generated fstab (`swap-swapfile.swap` active). Note `/swap` shows `compress=zstd:1` — btrfs compression is per-filesystem, so the per-subvolume "no compress" can't take effect; harmless, since btrfs never compresses a NODATACOW swapfile.

## Verified facts (live system, 2026-09-29)

| Item | Finding |
|---|---|
| Machine | ASUSTeK ROG Zephyrus G14 `GA402RJ_GA402RJ`, board `GA402RJ`, firmware **`GA402RJ.319` dated 2023-06-06** |
| CPU | AMD Ryzen 9 6900HS, 8C/16T; microcode updated early `0x0a404102` → `0x0a404108` |
| RAM | `MemTotal` 15572552 kB ≈ **14.85 GiB** |
| iGPU | Rembrandt 680M, `0000:07:00.0`, `0x1002:0x1681` → `card0`, `renderD129` |
| dGPU | Navi 23 (RX 6700S), `0000:03:00.0`, `0x1002:0x73ef` → `card1`, `renderD128` |
| **MUX state** | **`AsusMuxDgpu`** — `card1-eDP-1` is `connected`, i.e. the internal panel is wired to the **dGPU**. `card0` (iGPU) has only Writeback connectors |
| dGPU idle behaviour | `runtime_active_time=887280`, **`runtime_suspended_time=0`** over 887 s uptime — has never runtime-suspended. 700 MHz, 54 °C, `gpu_busy_percent=0`, `power1_average=6000000` (6 W), 638 MB VRAM allocated |
| What holds the dGPU | Every client is on `renderD128`: `cosmic-comp`, `Xwayland`, `cosmic-panel`, `cosmic-app-library`, `electron`, `nextcloud`, `xdg-desktop-portal`, `cef_server`. This is a consequence of the MUX, not a misconfiguration |
| `supergfxd` | **Was absent** — `services.supergfxd.enable = false`, no `supergfxctl` binary, no unit. `asusd` was enabled but owns only platform profiles / fans / EPP, never the MUX |
| Wi-Fi | MediaTek MT7921 `14c3:0616`, `mt7921e`. Sole network adapter; depends on `enableRedistributableFirmware` (was `true` only by default) |
| Sleep states | `/sys/power/mem_sleep` = **`[s2idle]`** only — no S3 on this platform |
| Swap (before) | `swapDevices = [ ]`, `boot.resumeDevice` unset, `zramSwap.enable = true` → hibernation impossible |
| `resume_offset` | **`60335360`**, from `btrfs inspect-internal map-swapfile -r /swap/swapfile` |
| `hardware.graphics.extraPackages` | Was `[ ]`. `modules/hardware/graphics.nix` had `mkIf` branches for `intel` and `nvidia` but **none for `amd`**, which is what this host sets |
| `fwupd` | Already `true`, but only implicitly via plasma6 — `fwupd` appeared nowhere in the repo |
| DisplayLink | `evdi` loaded with **0 users**, no dock attached. `dlm` was forced into `multi-user.target` unconditionally |
| Thunderbolt/USB4 | `/sys/bus/thunderbolt/devices/` empty — no `services.hardware.bolt` needed |
| Audio | Sink `alsa_output.pci-0000_07_00.6.analog-stereo` present and working; no CS35L41 amp quirk applies. **No change needed** |
| `thermald` | Correctly not imported (Intel-only) |
| Desktop host GPU vendor | `nvidia` — so the new `amd` branch affects **only** the laptop; no desktop rebuild |
| Formatter gotcha | Bare `nix fmt` hands alejandra no paths and reads stdin, failing with "unexpected end of file". Use `just fmt` (already documented at `justfile:42`) |
| Deprecation hit | `systemd.sleep.extraConfig` no longer has any effect in this nixpkgs → `systemd.sleep.settings.Sleep` |

## Decisions

- **Full hibernation, not just a logind policy.** Chosen over the no-disk-cost option because this platform is s2idle-only, so a closed lid otherwise keeps draining — and in `AsusMuxDgpu` that includes the dGPU.
- **`@swap` as a top-level subvolume**, not nested inside `@`, to match the existing layout and stay out of any future `@` snapshot.
- **`swapDevices` carries no `size`.** The file already exists; letting NixOS create it would not apply btrfs's NODATACOW requirement.
- **`/swap` mount declared in `hosts/laptop/default.nix`, not `hardware.nix`** — `hardware.nix` is generated and carries a "Do not modify" header, so a regenerate would drop it. It also keeps the mount next to the swap config it exists for.
- **`zramSwap` stays enabled.** Priority 5 vs. the file's default -2, so ordinary paging stays in RAM and the SSD is touched only for hibernation or real pressure.
- **DisplayLink moves to a udev trigger on USB vendor `0x17e9`** (universal across DL docks) rather than starting at every boot. Accepted trade-off: saves an idle service, but a misfiring rule means a dock silently drives nothing. **This is booth-facing hardware — see Risks.**
- **`rocmPackages.clr.icd` only**, not the full ROCm stack — the gap is the missing OpenCL ICD, nothing more.
- **`hardware.enableRedistributableFirmware` and `services.fwupd.enable` made explicit** rather than inherited from plasma6 / the graphics stack, so the only NIC's firmware does not depend on a desktop module staying imported.

## Remaining steps

### Stage 1 — Build and switch ✅ (2026-10-03)
- [x] `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link` (declined last time; this is where we stopped)
- [x] `nixos-rebuild switch --flake .#laptop`
- [x] Confirm `/swap` is mounted from the generated fstab, not the manual mount: `systemctl status swap-swapfile.swap`, `swapon --show` — zram at prio 5, `/swap/swapfile` at **-1** (kernel-assigned; still below zram, so the intent holds)
- [x] Commit the two files (repo style: small, scoped, 1–2 line subject)

### Stage 2 — Hibernation (needs a reboot; `resume_offset` is a kernel param)
- [ ] Reboot, then confirm `resume_offset=60335360` and `resume=/dev/disk/by-uuid/1bdf…` in `/proc/cmdline`
- [ ] `systemctl hibernate`, resume, and check the journal for a clean `PM: hibernation exit`
- [ ] Verify amdgpu survives hibernate/resume in `AsusMuxDgpu` — this is the most likely failure, since the dGPU is driving the panel
- [ ] Test the real path: close the lid on battery, wait past `HibernateDelaySec=45min`, confirm it transitioned suspend → hibernate
- [ ] Confirm lid-on-AC suspends and lid-while-docked is ignored

### Stage 3 — Actually stop the dGPU drain
- [ ] `supergfxctl -g` to confirm the daemon reads the mode
- [ ] `supergfxctl -m Hybrid`, then **reboot** (MUX changes need one)
- [ ] Re-check `card0`/`card1`: the internal eDP should move to the iGPU (`07:00.0`)
- [ ] Confirm `runtime_suspended_time` on `0000:03:00.0` is now non-zero and climbing
- [ ] Re-measure `power1_average` at idle and compare against the 6 W baseline
- [ ] Decide whether `Integrated` is wanted on battery, or whether `Hybrid` is enough

### Stage 4 — Validate the rest
- [ ] `clinfo` lists a platform (was empty) — confirms the OpenCL ICD
- [ ] **Test a real DisplayLink dock.** Attach it, confirm `dlm.service` is pulled in by the udev rule and displays light up. Until this passes, assume the dock is broken at a venue
- [ ] `fwupdmgr refresh && fwupdmgr get-upgrades` — BIOS is 3y3m old; decide on the update separately from this work

## Risks

- **`resume_offset` is tied to this exact swapfile.** Recreating or defragmenting `/swap/swapfile` changes it, and a stale value **corrupts the resume**. Re-run `btrfs inspect-internal map-swapfile -r` and update `hosts/laptop/default.nix` if the file is ever rebuilt. Noted in a comment at the assignment.
- **The DisplayLink udev trigger is unvalidated and booth-facing.** No dock was attached during this work, so the rule has never fired. See [[booth-network-gotchas]] territory: a dock that silently drives nothing at a venue is the exact failure class to avoid. If a booth is imminent, revert to `systemd.services.dlm.wantedBy = ["multi-user.target"]` until Stage 4 passes.
- **`evdi` is out-of-tree against `boot.kernelPackages = linuxPackages_latest`** (currently kernel 7.2.4). A kernel bump that outruns evdi breaks *this host's* build; pinning `boot.kernelPackages` is the way back. Noted in a comment.
- **Hibernation on an amdgpu-driven panel is the untested weak point.** If resume fails, the fallback is `HandleLidSwitch = "suspend"` with the swapfile left in place.
