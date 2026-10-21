/// @description Mod lifecycle event helpers (room transitions + per-step tick).
/// Called from obj_persistent: Step event (mod_enterscene, mod_tick) and
/// Room End event (mod_roomend). Degrades gracefully when modloader isn't ready.

/// True when the Lua modloader is up and mods are enabled.
function mod_live() {
    return variable_global_exists("mods_enabled") && global.mods_enabled
        && variable_global_exists("lua_state") && global.lua_state >= 0;
}

/// Fire "on_enter_room" once per room transition, passing the room name.
function mod_enterscene() {
    if (!variable_global_exists("prev_room") || prev_room == room) return;
    prev_room = room;
    if (!mod_live()) return;
    mod_arg_clear();
    mod_arg_str(0, room_get_name(room));
    mod_fire("on_enter_room");
    mod_arg_clear();
}

/// Fire "on_room_end" when the current room is about to end (Room End event),
/// passing the room name. Mods use this to sync state before a transition.
function mod_roomend() {
    if (!mod_live()) return;
    mod_arg_clear();
    mod_arg_str(0, room_get_name(room));
    mod_fire("on_room_end");
    mod_arg_clear();
}

/// Fire "on_update" every step, passing the current room name.
/// This is the mod's tick hook: networking pumps, timers, animations.
function mod_tick() {
    if (!mod_live()) return;
    mod_arg_clear();
    mod_arg_str(0, room_get_name(room));
    mod_fire("on_update");
    mod_arg_clear();
}
