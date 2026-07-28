import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import AstalBattery from "gi://AstalBattery"
import AstalBluetooth from "gi://AstalBluetooth"
import AstalNetwork from "gi://AstalNetwork"
import AstalMpris from "gi://AstalMpris"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import AstalWp from "gi://AstalWp"
import { createBinding, With } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import {
  brightness,
  setBrightness,
  cpu,
  memory,
  disk,
  localIp,
  waybarRunning,
  toggleWaybar,
  damageBlink,
  toggleDamageBlink,
  powerinfo,
  calendar,
} from "../lib/system"

const V = Gtk.Orientation.VERTICAL
const H = Gtk.Orientation.HORIZONTAL

const run = (cmd: string) => execAsync(["sh", "-c", cmd]).catch(console.error)

/** Spawn a floating terminal, keep it open until a keypress. */
const term = (cmd: string) =>
  run(
    `wezterm start --class floating-wezterm -- zsh -ic '${cmd}; echo; echo "[done - press any key]"; read -n1 -s'`,
  )

// ---------------------------------------------------------------- layout

export function Group({
  title,
  icon,
  children,
}: {
  title: string
  icon: string
  children?: any
}) {
  return (
    <box class="group" orientation={V}>
      <box class="group-head" spacing={8}>
        <image class="group-icon" iconName={icon} />
        <label class="group-title" label={title} xalign={0} hexpand />
      </box>
      <box class="group-body" orientation={V} spacing={4}>
        {children}
      </box>
    </box>
  )
}

/** A labelled on/off pill, matching the eww toggles. */
function Toggle({
  icon,
  label,
  state,
  onToggle,
}: {
  icon: string
  label: string
  state: any
  onToggle: (current: boolean) => void
}) {
  return (
    <box class="row" spacing={8}>
      <image class="icon" iconName={icon} />
      <label class="row-label" label={label} xalign={0} hexpand />
      <button
        class={state((on: boolean) => `toggle ${on ? "toggle-on" : "toggle-off"}`)}
        onClicked={() => onToggle(state.get())}
      >
        <label label={state((on: boolean) => (on ? "on" : "off"))} />
      </button>
    </box>
  )
}

// ---------------------------------------------------------------- header

function Header() {
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%H:%M")!,
  )
  const date = createPoll("", 60000, () =>
    GLib.DateTime.new_now_local().format("%A, %B %d")!,
  )

  const PowerBtn = ({
    icon,
    tip,
    cmd,
    danger = false,
  }: {
    icon: string
    tip: string
    cmd: string
    danger?: boolean
  }) => (
    <button
      class={`power-btn${danger ? " power-btn-danger" : ""}`}
      tooltipText={tip}
      onClicked={() => run(cmd)}
    >
      <image iconName={icon} />
    </button>
  )

  return (
    <box class="header" spacing={10}>
      <box orientation={V} hexpand valign={Gtk.Align.CENTER}>
        <label class="header-time" label={time} xalign={0} />
        <label class="header-date" label={date} xalign={0} />
      </box>
      <box spacing={6} halign={Gtk.Align.END}>
        <PowerBtn icon="system-lock-screen-symbolic" tip="lock" cmd="hyprlock" />
        <PowerBtn
          icon="system-suspend-symbolic"
          tip="suspend"
          cmd="systemctl suspend"
        />
        <PowerBtn
          icon="system-reboot-symbolic"
          tip="reboot"
          cmd="systemctl reboot"
        />
        <PowerBtn
          icon="system-shutdown-symbolic"
          tip="shutdown"
          cmd="systemctl poweroff"
          danger
        />
      </box>
    </box>
  )
}

// ---------------------------------------------------------------- network

function Network() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  return (
    <box orientation={V} spacing={4}>
      <With value={wifi}>
        {(w) =>
          w ? (
            <box class="row" spacing={8}>
              <image class="icon" iconName={createBinding(w, "iconName")} />
              <box orientation={V} hexpand>
                <label
                  class="row-label"
                  xalign={0}
                  label={createBinding(w, "ssid")((s) => s || "disconnected")}
                />
                <label
                  class="row-sub"
                  xalign={0}
                  label={createBinding(w, "strength")((s) => `signal ${s}%`)}
                />
              </box>
            </box>
          ) : (
            <box class="row" spacing={8}>
              <image class="icon" iconName="network-wireless-offline-symbolic" />
              <label class="row-label" xalign={0} hexpand label="no wifi device" />
            </box>
          )
        }
      </With>

      <box class="row" spacing={8}>
        <image class="icon" iconName="network-wired-symbolic" />
        <label class="row-label" label={localIp} xalign={0} hexpand />
        <button
          class="icon-btn"
          tooltipText="copy IP"
          onClicked={() => run(`wl-copy '${localIp.get()}'`)}
        >
          <image iconName="edit-copy-symbolic" />
        </button>
      </box>
    </box>
  )
}

// ---------------------------------------------------------------- bluetooth

function Bluetooth() {
  const bt = AstalBluetooth.get_default()
  const powered = createBinding(bt, "isPowered")
  const devices = createBinding(bt, "devices")

  const connected = devices((ds: AstalBluetooth.Device[]) => {
    const names = ds.filter((d) => d.connected).map((d) => d.alias || d.name)
    return names.length ? names.join(", ") : "no devices"
  })

  return (
    <box class="row" spacing={8}>
      <image
        class="icon"
        iconName={powered((p: boolean) =>
          p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic",
        )}
      />
      <box orientation={V} hexpand>
        <label
          class="row-label"
          xalign={0}
          label={powered((p: boolean) => `bluetooth: ${p ? "on" : "off"}`)}
        />
        <label class="row-sub" xalign={0} label={connected} />
      </box>
      <button
        class={powered((p: boolean) =>
          `toggle ${p ? "toggle-on" : "toggle-off"}`,
        )}
        onClicked={() => bt.toggle()}
      >
        <label label={powered((p: boolean) => (p ? "on" : "off"))} />
      </button>
    </box>
  )
}

// ---------------------------------------------------------------- audio

function Volume() {
  const speaker = AstalWp.get_default()!.defaultSpeaker

  return (
    <box class="row" spacing={8}>
      <button
        class="icon-btn"
        tooltipText="toggle mute"
        onClicked={() => speaker.set_mute(!speaker.mute)}
      >
        <image iconName={createBinding(speaker, "volumeIcon")} />
      </button>
      <slider
        hexpand
        value={createBinding(speaker, "volume")}
        onChangeValue={({ value }) => speaker.set_volume(value)}
      />
      <label
        class="row-sub"
        label={createBinding(speaker, "volume")((v) => `${Math.round(v * 100)}%`)}
      />
    </box>
  )
}

/**
 * Per-application volume. This replaces the shell script that used to emit
 * yuck: astal exposes the streams directly.
 */
function AppVolume() {
  const wp = AstalWp.get_default()!
  const streams = createBinding(wp, "streams")

  return (
    <With value={streams}>
      {(list: AstalWp.Endpoint[]) => (
        <box orientation={V} spacing={4}>
          {list.map((s) => (
            <box class="row row-sub-item" spacing={8}>
              <label
                class="row-sub"
                xalign={0}
                label={createBinding(s, "description")((d) =>
                  (d || "app").slice(0, 18),
                )}
              />
              <slider
                hexpand
                value={createBinding(s, "volume")}
                onChangeValue={({ value }) => s.set_volume(value)}
              />
            </box>
          ))}
        </box>
      )}
    </With>
  )
}

// ---------------------------------------------------------------- brightness

function Brightness() {
  return (
    <box class="row" spacing={8}>
      <image class="icon" iconName="display-brightness-symbolic" />
      <slider
        hexpand
        min={1}
        max={100}
        value={brightness}
        onChangeValue={({ value }) => setBrightness(value)}
      />
      <label class="row-sub" label={brightness((b: number) => `${b}%`)} />
    </box>
  )
}

// ---------------------------------------------------------------- media

function Media() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box class="row" orientation={V} spacing={4}>
      <With value={players}>
        {(list: AstalMpris.Player[]) => {
          if (!list.length)
            return (
              <label class="row-sub" xalign={0} label="(nothing playing)" />
            )
          const p = list[0]
          return (
            <box orientation={V} spacing={4}>
              <label
                class="row-label"
                xalign={0}
                maxWidthChars={34}
                ellipsize={3}
                label={createBinding(p, "title")((t) => t || "(untitled)")}
              />
              <label
                class="row-sub"
                xalign={0}
                maxWidthChars={34}
                ellipsize={3}
                label={createBinding(p, "artist")((a) => a || "")}
              />
              <box spacing={8} halign={Gtk.Align.CENTER}>
                <button class="media-btn" onClicked={() => p.previous()}>
                  <image iconName="media-skip-backward-symbolic" />
                </button>
                <button class="media-btn" onClicked={() => p.play_pause()}>
                  <image
                    iconName={createBinding(p, "playbackStatus")((s) =>
                      s === AstalMpris.PlaybackStatus.PLAYING
                        ? "media-playback-pause-symbolic"
                        : "media-playback-start-symbolic",
                    )}
                  />
                </button>
                <button class="media-btn" onClicked={() => p.next()}>
                  <image iconName="media-skip-forward-symbolic" />
                </button>
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}

// ---------------------------------------------------------------- system

function Meter({ icon, value }: { icon: string; value: any }) {
  return (
    <box class="row" spacing={8}>
      <image class="icon" iconName={icon} />
      <levelbar hexpand minValue={0} maxValue={100} value={value} />
      <label class="row-sub" label={value((v: number) => `${v}%`)} />
    </box>
  )
}

function SystemInfo() {
  return (
    <box orientation={V} spacing={4}>
      <Meter icon="utilities-system-monitor-symbolic" value={cpu} />
      <Meter icon="drive-harddisk-solidstate-symbolic" value={memory} />
      <Meter icon="drive-harddisk-symbolic" value={disk} />
    </box>
  )
}

// ---------------------------------------------------------------- battery

/**
 * Charge thresholds / cycle count / health are not exposed by AstalBattery,
 * so they still come from sysfs. Live draw does come from astal.
 */
const batteryExtra = createPoll(
  "",
  30000,
  ["sh", "-c", "/etc/nixos/dotfiles/scripts/battery-extra"],
  (out) => out.trim(),
)

function Battery() {
  const bat = AstalBattery.get_default()
  const pp = AstalPowerProfiles.get_default()

  return (
    <box orientation={V} spacing={4}>
      <box class="row" spacing={8} visible={createBinding(bat, "isPresent")}>
        <image class="icon" iconName={createBinding(bat, "iconName")} />
        <label
          class="row-label"
          xalign={0}
          hexpand
          label={createBinding(bat, "percentage")((p) => `${Math.round(p * 100)}%`)}
        />
        <label
          class="row-sub"
          label={createBinding(bat, "energyRate")((w) => `${w.toFixed(1)} W`)}
        />
      </box>

      <box class="row" spacing={8}>
        <image class="icon" iconName="battery-level-90-symbolic" />
        <label class="row-sub" xalign={0} hexpand label={batteryExtra} />
        <button
          class="icon-btn"
          tooltipText="full tlp-stat -b"
          onClicked={() => term("doas tlp-stat -b")}
        >
          <image iconName="dialog-information-symbolic" />
        </button>
      </box>

      {/* power mode: the eww TODO, now real */}
      <box class="row" spacing={6}>
        <image class="icon" iconName="power-profile-balanced-symbolic" />
        {pp.get_profiles().map(({ profile }) => (
          <button
            class={createBinding(pp, "activeProfile")((a) =>
              `pp-btn${a === profile ? " pp-btn-active" : ""}`,
            )}
            hexpand
            onClicked={() => pp.set_active_profile(profile)}
          >
            <label label={profile.replace("-", " ")} />
          </button>
        ))}
      </box>
    </box>
  )
}

// ---------------------------------------------------------------- rebuild

function Rebuild() {
  return (
    <box orientation={V} spacing={6}>
      <box spacing={6} homogeneous>
        <button
          class="rb-btn"
          tooltipText="stage for next boot"
          onClicked={() => term("doas nixos-rebuild boot")}
        >
          <label label="boot" />
        </button>
        <button
          class="rb-btn"
          tooltipText="apply now"
          onClicked={() => term("doas nixos-rebuild switch")}
        >
          <label label="switch" />
        </button>
      </box>
      <button
        class="rb-btn rb-btn-accent"
        tooltipText="megayeet"
        onClicked={() => term("megayeet")}
      >
        <label label="megayeet" />
      </button>
    </box>
  )
}

function PowerOverview() {
  return (
    <box class="group" orientation={V} vexpand>
      <box class="group-head" spacing={8}>
        <image class="group-icon" iconName="power-profile-performance-symbolic" />
        <label class="group-title" label="power overview" xalign={0} hexpand />
      </box>
      <Gtk.ScrolledWindow vexpand hexpand>
        <label class="pi-body" xalign={0} yalign={0} label={powerinfo} />
      </Gtk.ScrolledWindow>
    </box>
  )
}

// ---------------------------------------------------------------- launcher

function Launcher() {
  const Btn = ({ icon, label, cmd }: { icon: string; label: string; cmd: string }) => (
    <button class="launcher-btn" hexpand onClicked={() => run(cmd)}>
      <box spacing={6} halign={Gtk.Align.CENTER}>
        <image iconName={icon} />
        <label label={label} />
      </box>
    </button>
  )

  return (
    <box spacing={8} homogeneous>
      <Btn icon="view-app-grid-symbolic" label="apps" cmd="wofi --show drun" />
      <Btn icon="system-run-symbolic" label="run" cmd="wofi --show run" />
      <Btn icon="focus-windows-symbolic" label="windows" cmd="wofi --show window" />
    </box>
  )
}

// ---------------------------------------------------------------- window

export default function Panel() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="panel"
      namespace="ags-panel"
      application={app}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      class="panel-root"
    >
      {/* full-screen transparent root; the card itself is centered */}
      <box class="flyout" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <box class="col-left" orientation={V} spacing={8}>
          <Header />
          <Group title="network" icon="network-wireless-symbolic">
            <Network />
          </Group>
          <Group title="bluetooth" icon="bluetooth-symbolic">
            <Bluetooth />
          </Group>
          <Group title="volume" icon="audio-volume-high-symbolic">
            <Volume />
            <AppVolume />
          </Group>
          <Group title="brightness" icon="display-brightness-symbolic">
            <Brightness />
          </Group>
          <Group title="media" icon="multimedia-player-symbolic">
            <Media />
          </Group>
          <Group title="system" icon="utilities-system-monitor-symbolic">
            <SystemInfo />
          </Group>
          <Group title="battery" icon="battery-symbolic">
            <Battery />
          </Group>
          <Group title="toggles" icon="preferences-system-symbolic">
            <Toggle
              icon="view-dual-symbolic"
              label="waybar"
              state={waybarRunning}
              onToggle={toggleWaybar}
            />
            <Toggle
              icon="preferences-desktop-display-symbolic"
              label="damage_blink"
              state={damageBlink}
              onToggle={toggleDamageBlink}
            />
          </Group>
          <Group title="calendar" icon="x-office-calendar-symbolic">
            <label class="calendar" xalign={0} label={calendar} />
          </Group>
          <Group title="launcher" icon="view-app-grid-symbolic">
            <Launcher />
          </Group>
        </box>

        <Gtk.Separator class="vsep" orientation={V} />

        <box class="col-right" orientation={V} spacing={10}>
          <Group title="rebuild" icon="software-update-available-symbolic">
            <Rebuild />
          </Group>
          <PowerOverview />
        </box>
      </box>
    </window>
  )
}
