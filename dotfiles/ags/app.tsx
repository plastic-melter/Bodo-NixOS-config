import app from "ags/gtk4/app"
import style from "./style.scss"
import Panel from "./widget/Panel"
import Help from "./widget/Help"

app.start({
  instanceName: "shell",
  css: style,
  // Build on Adwaita rather than letting the system theme interfere.
  // NOTE: `* { all: unset }` (the eww habit) is explicitly discouraged in GTK4.
  gtkTheme: "Adwaita",
  main() {
    Panel()
    Help()
  },
})
