import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import { Group } from "./Panel"

const V = Gtk.Orientation.VERTICAL

function Kb({ keys, desc }: { keys: string; desc: string }) {
  return (
    <box class="kb-row" spacing={10}>
      <label class="kb-keys" label={keys} widthRequest={120} xalign={0} />
      <label class="kb-desc" label={desc} xalign={0} hexpand />
    </box>
  )
}

export default function Help() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="help"
      namespace="ags-help"
      application={app}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      class="panel-root"
    >
      <box
        class="flyout help"
        orientation={V}
        spacing={10}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <box class="help-head" spacing={10}>
          <label class="help-title" label="keybinds" xalign={0} hexpand />
          <label
            class="help-sub"
            label="mod = super   -   super+h to close"
            xalign={1}
          />
        </box>

        <box spacing={10} homogeneous>
          <box orientation={V} spacing={10}>
            <Group title="launch" icon="applications-utilities-symbolic">
              <Kb keys="mod Return" desc="terminal (wezterm)" />
              <Kb keys="mod Shift Return" desc="floating terminal" />
              <Kb keys="mod Z" desc="app launcher (wofi)" />
              <Kb keys="mod R" desc="drawer (nwg)" />
              <Kb keys="mod E" desc="files (thunar)" />
              <Kb keys="mod V" desc="clipboard history" />
              <Kb keys="mod T" desc="cycle theme" />
              <Kb keys="mod Shift C" desc="colour picker" />
              <Kb keys="mod Q" desc="control panel" />
              <Kb keys="mod H" desc="this help" />
            </Group>

            <Group title="window" icon="focus-windows-symbolic">
              <Kb keys="mod Shift Q" desc="close window" />
              <Kb keys="mod F" desc="fullscreen" />
              <Kb keys="mod Shift Space" desc="toggle floating" />
              <Kb keys="mod Space" desc="pseudo-tile" />
              <Kb keys="mod C" desc="centre window" />
              <Kb keys="mod + LMB" desc="drag to move" />
              <Kb keys="mod + RMB" desc="drag to resize" />
            </Group>

            <Group title="workspaces" icon="view-grid-symbolic">
              <Kb keys="mod 1-5" desc="go to workspace" />
              <Kb keys="mod Shift 1-5" desc="send window there" />
              <Kb keys="mod A / S" desc="prev / next workspace" />
              <Kb keys="mod scroll" desc="cycle workspaces" />
              <Kb keys="mod PgUp/Dn" desc="prev / next (hyprnome)" />
              <Kb keys="mod Shift PgUp/Dn" desc="move window + follow" />
            </Group>
          </box>

          <box orientation={V} spacing={10}>
            <Group title="focus and move" icon="go-next-symbolic">
              <Kb keys="mod arrows" desc="move focus" />
              <Kb keys="mod h j k l" desc="move focus (vim)" />
              <Kb keys="mod Shift arrows" desc="move window" />
            </Group>

            <Group title="resize" icon="view-fullscreen-symbolic">
              <Kb keys="mod Ctrl arrows" desc="resize active" />
              <Kb keys="mod Ctrl h j k l" desc="resize active (vim)" />
            </Group>

            <Group title="screenshot" icon="camera-photo-symbolic">
              <Kb keys="Print" desc="whole output" />
              <Kb keys="mod Print" desc="region" />
              <Kb keys="mod Shift Print" desc="active window" />
            </Group>

            <Group title="audio and display" icon="audio-volume-high-symbolic">
              <Kb keys="Vol +/- Mute" desc="output volume" />
              <Kb keys="Mic Mute" desc="toggle mic" />
              <Kb keys="Bright +/-" desc="screen brightness" />
              <Kb keys="mod X" desc="toggle waybar" />
              <Kb keys="mod Alt E" desc="external monitor" />
            </Group>

            <Group title="system" icon="system-lock-screen-symbolic">
              <Kb keys="mod Shift L" desc="lock screen" />
              <Kb keys="mod Shift E" desc="logout (wlogout)" />
            </Group>
          </box>
        </box>
      </box>
    </window>
  )
}
