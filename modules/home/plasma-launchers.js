// Evaluated inside plasmashell; the caller supplies applyChanges.
// Keep desktop-file IDs instead of generation-specific Nix store URLs.
function stableLauncher(launcher) {
    var match = launcher.match(/^file:\/\/\/nix\/store\/[^/]+\/share\/applications\/([^?#]+\.desktop)(\?[^#]*)?$/);
    // Nested application directories become hyphenated desktop-file IDs.
    var stable = match
        ? "applications:" + match[1].replace(/\//g, "-") + (match[2] || "")
        : launcher;

    // The packaged Mono launcher includes the engine version in its ID.
    // Our alias follows the selected package across engine upgrades.
    return stable.replace(
        /^applications:org\.godotengine\.Godot[0-9]+(?:\.[0-9]+)*-mono\.desktop(?=\?|$)/,
        "applications:godot.desktop"
    );
}

var changes = [];
panels().forEach(function (panel) {
    panel.widgets().forEach(function (widget) {
        if (widget.type !== "org.kde.plasma.icontasks" && widget.type !== "org.kde.plasma.taskmanager") {
            return;
        }

        widget.currentConfigGroup = ["General"];
        var before = widget.readConfig("launchers", []);
        var after = before.map(stableLauncher);
        if (JSON.stringify(before) === JSON.stringify(after)) {
            return;
        }

        changes.push({panel: panel.id, widget: widget.id, before: before, after: after});
        if (applyChanges) {
            widget.writeConfig("launchers", after);
            widget.reloadConfig();
        }
    });
});
print(JSON.stringify(changes));
