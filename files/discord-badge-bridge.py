#!/usr/bin/env python3
# Forwards Discord's unread badge to Dash to Dock. Installed by the discord-badge
# module and started by discord-badge-bridge.service.
#
# Discord sends com.canonical.Unity.LauncherEntry "Update" signals for
# application://discord, but the dock only knows the Flatpak desktop ID. This
# script repeats each update for DST_URI and clears the badge when Discord exits.
#
# If the badge stops showing after a Discord update, check the URI it sends with
#   dbus-monitor --session "interface='com.canonical.Unity.LauncherEntry'"
# and update SRC_URIS. For a non-Flatpak Discord, change DST_URI to its .desktop name.
import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

IFACE = "com.canonical.Unity.LauncherEntry"
SRC_URIS = {"application://discord", "application://discord.desktop"}
DST_URI = "application://com.discordapp.Discord.desktop"
PATH = "/com/canonical/unity/launcherentry/discordbridge"

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
senders = set()


def emit(props):
    bus.emit_signal(None, PATH, IFACE, "Update",
                    GLib.Variant("(sa{sv})", (DST_URI, props)))


def on_update(conn, sender, path, iface, member, params):
    uri, props = params.unpack()
    if uri not in SRC_URIS:
        return
    senders.add(sender)
    emit({k: params.get_child_value(1).lookup_value(k, None) for k in props})


def on_owner_changed(conn, sender, path, iface, member, params):
    name, old, new = params.unpack()
    if name in senders and not new:  # Discord exited: clear the badge
        senders.discard(name)
        emit({"count": GLib.Variant("x", 0),
              "count-visible": GLib.Variant("b", False)})


bus.signal_subscribe(None, IFACE, "Update", None, None,
                     Gio.DBusSignalFlags.NONE, on_update)
bus.signal_subscribe("org.freedesktop.DBus", "org.freedesktop.DBus",
                     "NameOwnerChanged", "/org/freedesktop/DBus", None,
                     Gio.DBusSignalFlags.NONE, on_owner_changed)
GLib.MainLoop().run()
