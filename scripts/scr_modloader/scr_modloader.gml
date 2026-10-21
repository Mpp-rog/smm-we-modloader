/// @description Lua modloader for SMM:WE (Windows + Linux).
/// Native bridge = swe_lua extension (sl_* functions over Lua 5.4).
/// Every entry point degrades gracefully: if the extension is missing or a
/// call throws, mods are disabled and the game keeps running (never crashes).
///
/// Mod delivery: each mod is a ZIP file placed in working_directory/mods/.
/// The ZIP must contain a top-level main.lua. It may also contain folders
/// assets/ sounds/ stuff/ (and any other entries) which are extracted under
/// mods/<safe-name>/ so the game can read them at runtime.
/// The loader creates mods/ at runtime if it is missing.

/// True only when a Lua state exists and mods are switched on.
function mod_ready() {
    return variable_global_exists("mods_enabled")
        && global.mods_enabled
        && variable_global_exists("lua_state")
        && global.lua_state >= 0;
}

/// Native string_pos replacement: finds first occurrence of _needle in _haystack.
/// Uses string_copy + loop to avoid a compiler issue with the built-in string_pos.
function sml_string_pos(_haystack, _needle) {
    var _h = string_length(_haystack);
    var _n = string_length(_needle);
    if (_n == 0 || _h < _n) return 0;
    for (var _i = 1; _i <= _h - _n + 1; _i++) {
        if (string_copy(_haystack, _i, _n) == _needle) return _i;
    }
    return 0;
}


/// Append a line to the in-memory mod log and to modloader.log in
/// working_directory (file output survives even when show_debug_message is
/// swallowed by a release runner with no IDE console).
function mod_log(_msg) {
    // NB: the global must not be named "mod_log" — GMS 2.3 stores functions as
    // globals, so that name would resolve to this function, not an array.
    if (!variable_global_exists("mod_log_lines") || !is_array(global.mod_log_lines)) global.mod_log_lines = [];
    var _line = "[modloader] " + string(_msg);
    array_push(global.mod_log_lines, _line);
    show_debug_message(_line);
    try {
        var _p = working_directory + "modloader.log";
        var _f = file_text_open_append(_p);
        file_text_write_string(_f, _line);
        file_text_writeln(_f);
        file_text_close(_f);
    } catch (_e) { /* file logging is best-effort */ }
}

/// Lua bootstrap source: builds __hooks, __store and the swe.* API that
/// mod scripts use to register event callbacks.
function mod_bootstrap_src() {
    return @"
__hooks = __hooks or {}
__store = __store or {}
swe = swe or {}
function swe.on(ev, fn)
    if type(ev) ~= 'string' or type(fn) ~= 'function' then return false end
    if __hooks[ev] == nil then __hooks[ev] = {} end
    table.insert(__hooks[ev], fn)
    return true
end
function swe.log(msg) print('[mod] ' .. tostring(msg)) end
function swe.store_get(k) return __store[k] end
function swe.store_set(k, v) __store[k] = v return v end
function swe.mods() return __store end
swe.net = {}
function swe.net.listen(port) return net.listen(port) end
function swe.net.connect(host, port) return net.connect(host, port) end
function swe.net.accept(fd) return net.accept(fd) end
function swe.net.send(fd, data) return net.send(fd, data) end
function swe.net.recv(fd) return net.recv(fd) end
function swe.net.close(fd) net.close(fd) end
function swe.net.sendline(fd, s) return net.send(fd, tostring(s) .. '\n') end
";
}

/// Create the Lua state, open libs, run the bootstrap. Returns true on success.
function mod_init() {
    global.mods_supported = false;
    global.mods_enabled = false;
    global.mods_list = [];
    global.lua_state = -1;
    if (!variable_global_exists("mod_log_lines") || !is_array(global.mod_log_lines)) global.mod_log_lines = [];

    var _err = "";
    try {
        var _L = sl_newstate();
        if (_L > 0) {
            sl_openlibs(_L);
            global.lua_state = _L;
            global.mods_supported = true;

            var _st = sl_dostring(_L, mod_bootstrap_src());
            if (_st != 0) {
                _err = "bootstrap error: " + string(sl_lasterror());
                sl_close(_L);
                global.lua_state = -1;
            }
        } else {
            _err = "sl_newstate failed";
        }
    } catch (_e) {
        _err = "exception: " + string(_e);
        global.lua_state = -1;
        global.mods_supported = false;
    }
    // NB: returns stay outside the try/catch - see the note in mod_run_main.
    if (_err != "") {
        mod_log("mod_init failed: " + _err + "; mods disabled");
        return false;
    }

    global.mods_enabled = true;
    mod_log("Lua modloader initialised");
    return true;
}


/// Strip path/extension and keep only safe lowercase alphanumeric + underscore chars.
function mod_safe_name(_zipname) {
    var _base = zip_basename(_zipname);
    // find last '.'
    var _last_dot = 0;
    for (var _i = 1; _i <= string_length(_base); _i++) {
        if (string_char_at(_base, _i) == ".") _last_dot = _i;
    }
    if (_last_dot > 0) _base = string_copy(_base, 1, _last_dot - 1);
    var _out = "";
    for (var _i = 1; _i <= string_length(_base); _i++) {
        var _c = string_char_at(_base, _i);
        if (string_letters(_c) != "" || string_digits(_c) != "" || _c == "_") _out += string_lower(_c);
    }
    if (string_length(_out) == 0) _out = "mod";
    return _out;
}

/// Last path component (filename) of a path.
function zip_basename(_path) {
    var _s = string_replace(_path, "\\", "/");
    var _len = string_length(_s);
    var _last = 0;
    for (var _i = 1; _i <= _len; _i++) {
        if (string_char_at(_s, _i) == "/") _last = _i;
    }
    if (_last == 0) return _s;
    return string_copy(_s, _last + 1, 999);
}

/// Absolute extraction root for a zip file name.
function mod_extract_root(_zipname) {
    return working_directory + "mods/" + mod_safe_name(_zipname) + "/";
}

/// Quote a path so the POSIX shell takes it literally.
function mod_sh_quote(_s) {
    return "'" + string_replace_all(_s, "'", "'\\''") + "'";
}

/// Wrap a GML string as a Lua single-quoted literal.
function mod_lua_str(_s) {
    var _o = string_replace_all(_s, "\\", "\\\\");
    _o = string_replace_all(_o, "'", "\\'");
    return "'" + _o + "'";
}

/// Absolute path of the save/working directory *as the shell sees it*.
///
/// GML file calls resolve working_directory (which the Linux runner reports as
/// the relative "assets/") against the save directory, e.g. ~/.config/SMM_WE,
/// while a shell spawned from Lua resolves that very same string against the
/// folder holding the executable. Shelling out with the relative path
/// therefore extracted every mod next to the binary, where the game could not
/// see it, and each mod failed with "zip missing main.lua after extract".
///
/// To get the real path we drop a marker file into the save directory with GML
/// (so it lands in the right place) and have the shell locate that marker
/// under $HOME - this works wherever the runner keeps its saves (~/.config,
/// snap, flatpak, ...) without hard-coding any of those layouts.
function mod_shell_root() {
    if (variable_global_exists("mod_shell_root_abs") && is_string(global.mod_shell_root_abs) && global.mod_shell_root_abs != "")
        return global.mod_shell_root_abs;
    global.mod_shell_root_abs = "";
    if (!mod_ready()) return "";

    var _marker = ".mmwe_save_marker";
    var _mp = working_directory + _marker;
    var _wrote = false;
    try {
        var _fh = file_text_open_write(_mp);
        file_text_write_string(_fh, "save");
        file_text_close(_fh);
        _wrote = true;
    } catch (_e) {
        mod_log("save marker write failed: " + string(_e));
    }
    if (!_wrote) return "";

    // Fast path: the standard desktop location (<game_save_id> under
    // ~/.config); bounded search for the marker as the fallback.
    var _cmd = "test -f \"$HOME/.config/" + game_save_id + "/" + _marker + "\""
        + " && printf %s \"$HOME/.config/" + game_save_id + "\""
        + " || find \"$HOME\" -maxdepth 5 -name " + _marker + " -printf %h 2>/dev/null | head -1";
    var _lua = "local p = io.popen(" + mod_lua_str(_cmd) + "); local out = ''; "
        + "if p then out = p:read('*a') or ''; p:close(); end "
        + "out = out:gsub('%s+$', ''); "
        + "swe.store_set('mod.shellroot', out);";
    try {
        var _st = sl_dostring(global.lua_state, _lua);
        if (_st != 0) mod_log("save marker probe error: " + string(sl_lasterror()));
    } catch (_e) {
        mod_log("save marker probe exception: " + string(_e));
    }
    var _root = mod_store_get_str("mod.shellroot");
    try { file_delete(_mp); } catch (_e) { /* marker removal is best effort */ }
    if (_root == "") {
        mod_log("could not resolve the save directory for the shell");
        return "";
    }
    global.mod_shell_root_abs = _root;
    return _root;
}

/// Load every mod in working_directory + "mods/" (each is a .zip containing main.lua).
/// Returns the number of mods that loaded successfully.
function mod_load_all() {
    if (!mod_ready()) return 0;
    var _dir = working_directory + "mods/";
    if (!directory_exists(_dir)) {
        directory_create(_dir);
        mod_log("created mods dir: " + _dir);
        return 0;
    }

    var _count = 0;
    global.mods_list = [];
    var _ziplist = [];
    var _entry = file_find_first(_dir + "*.zip", 0);
    while (_entry != "" && !is_undefined(_entry)) {
        if (_entry != "." && _entry != "..") {
            _ziplist[array_length(_ziplist)] = _entry;
        }
        _entry = file_find_next();
    }
    file_find_close();
    mod_log("found " + string(array_length(_ziplist)) + " zip(s) in " + _dir);

    for (var _i = 0; _i < array_length(_ziplist); _i++) {
        var _zip = _ziplist[_i];
        mod_log("processing zip: " + _zip);
        var _stem = mod_safe_name(_zip);
        var _root = mod_extract_root(_zip);
        var _main_path = _root + "main.lua";
        if (file_exists(_main_path)) {
            // already extracted previously
            if (mod_run_main(_main_path, _stem)) _count++;
            continue;
        }
        var _zpath = _dir + _zip;
        if (!file_exists(_zpath)) continue;

        // Extract the zip with the shell (unzip). This bypasses the GML
        // buffer-based zip parser which is unreliable on the Linux runner
        // (buffer_get_size/buffer_u32 issues).
        //
        // The zip and the destination MUST be absolute paths: GML resolves
        // working_directory against the save directory, while a shell spawned
        // from Lua resolves the same relative string against the executable's
        // folder. Relative paths used to extract every mod next to the binary,
        // where the game could never read them back, so every mod failed with
        // "zip missing main.lua after extract".
        var _shell_root = mod_shell_root();
        if (_shell_root == "") {
            mod_log("skipping " + _zip + " - no shell-visible save directory");
            continue;
        }
        // The whole shell job is kept deliberately short: the native bridge
        // truncates long chunks passed to sl_dostring, which used to cut the
        // command in half (sh: "end of file unexpected (expecting done)"). So
        // cd into mods/ once and use the short safe mod name from there on.
        var _q_mods = mod_sh_quote(_shell_root + "/mods");
        var _q_stem = mod_sh_quote(_stem);
        var _main_rel = _stem + "/main.lua";
        var _extract_cmd = "cd " + _q_mods
            + " && mkdir -p " + _q_stem
            + " && unzip -o " + mod_sh_quote(_zip) + " -d " + _q_stem + " >/dev/null 2>&1"
            // Some zips wrap everything in a single folder. Pull main.lua up to
            // the extraction root HERE, in the shell: the runner's file_exists
            // reliably sees files at the root of a freshly extracted folder but
            // not one level deeper, so the game can then just look for
            // <root>/main.lua instead of walking a directory tree.
            + "; for t in 1 2 3; do"
            + " [ -f " + mod_sh_quote(_main_rel) + " ] && break"
            + "; for d in " + _q_stem + "/*/; do"
            + " [ -f \"${d}main.lua\" ] || continue"
            + "; mv \"$d\"* " + _q_stem + "/ 2>/dev/null; rmdir \"$d\" 2>/dev/null; break; done"
            + "; [ -f " + mod_sh_quote(_main_rel) + " ] || sleep 0.3; done"
            + "; [ -f " + mod_sh_quote(_main_rel) + " ] && echo HAVE_MAIN"
            + " || { echo NO_MAIN; find " + _q_stem + " -name main.lua 2>/dev/null | head -3; }";
        var _extract_code = "local h = io.popen(" + mod_lua_str(_extract_cmd) + "); "
            + "local o = h:read('*a') or ''; h:close(); "
            + "o = o:gsub('[\\r\\n]+', ' | '); "
            + "swe.store_set('mod.extractout', o:sub(1, 400));";
        var _err = "";
        var _report = "";
        try {
            var _st = sl_dostring(global.lua_state, _extract_code);
            if (_st != 0) _err = string(sl_lasterror());
            _report = mod_store_get_str("mod.extractout");
        } catch (_e) {
            _err = "exception: " + string(_e);
        }
        // NB: every continue/return in this loop lives OUTSIDE try/catch blocks
        // on purpose - on the VM runner a continue or return inside a try block
        // can unwind the enclosing loop and silently skip the remaining mods.
        if (_err != "") {
            mod_log("zip extract error: " + _zip + " (" + _err + ")");
            continue;
        }
        // The shell has already flattened a one-folder-deep layout, so
        // main.lua is either at the extraction root or not present at all.
        if (!file_exists(_root + "main.lua")) {
            mod_log("zip missing main.lua after extract: " + _zip + " (" + _report + ")");
            continue;
        }
        mod_log("extracted zip: " + _zip + " (" + _report + ")");
        if (mod_run_main(_main_path, _stem)) _count++;
    }

    mod_log("loaded " + string(_count) + " mod(s)");
    return _count;
}

/// Run a mod's main.lua that has already been extracted to disk. Returns true on success.
function mod_run_main(_path, _name) {
    if (!mod_ready()) return false;
    if (!file_exists(_path) && file_exists(_path + ".lua")) _path += ".lua";
    if (!file_exists(_path)) {
        mod_log("missing main.lua: " + _path);
        return false;
    }

    var _fh = file_text_open_read(_path);
    var _code = "";
    while (!file_text_eof(_fh)) {
        _code += file_text_read_string(_fh) + "\n";
        file_text_readln(_fh);
    }
    file_text_close(_fh);

    var _err = "";
    try {
        var _st = sl_dostring(global.lua_state, _code);
        if (_st != 0) _err = string(sl_lasterror());
    } catch (_e) {
        _err = "exception: " + string(_e);
    }
    // NB: the returns below stay OUTSIDE the try/catch. On the VM runner a
    // return inside a try block can unwind past the calling function too, which
    // used to abort mod_load_all's loop early and silently skip every mod that
    // came after a failing one.
    if (_err != "") {
        mod_log("error in '" + string(_name) + "': " + _err);
        return false;
    }

    array_push(global.mods_list, _name);
    mod_log("loaded mod '" + string(_name) + "'");
    return true;
}

/// Fire all callbacks registered for an event (stage args first via mod_arg_*).
/// Returns number of callbacks run, or -(count) if some threw.
function mod_fire(_ev) {
    if (!mod_ready()) return 0;
    try {
        var _n = sl_fire(global.lua_state, string(_ev));
        if (_n < 0) mod_log("hook '" + string(_ev) + "' errors: " + string(sl_lasterror()));
        return _n;
    } catch (_e) {
        mod_log("mod_fire exception on '" + string(_ev) + "': " + string(_e));
        return 0;
    }
}

/// --- staged call arguments (max 8) ---------------------------------------
function mod_arg_clear() {
    if (!mod_ready()) return;
    sl_arg_clear();
}

function mod_arg_num(_i, _v) {
    if (!mod_ready()) return;
    sl_arg_num(_i, _v);
}

function mod_arg_str(_i, _s) {
    if (!mod_ready()) return;
    sl_arg_str(_i, _s);
}

/// --- mod store (values mods expose to the game and vice versa) -----------
function mod_store_get_num(_key) {
    if (!mod_ready()) return 0;
    return sl_store_get_num(global.lua_state, _key);
}

function mod_store_get_str(_key) {
    if (!mod_ready()) return "";
    return sl_store_get_str(global.lua_state, _key);
}

/// -1 absent, 0 nil, 1 bool, 3 number, 4 string, 5 table, 6 function.
function mod_store_get_type(_key) {
    if (!mod_ready()) return -1;
    return sl_store_get_type(global.lua_state, _key);
}

function mod_store_set_num(_key, _v) {
    if (!mod_ready()) return;
    sl_store_set_num(global.lua_state, _key, _v);
}

function mod_store_set_str(_key, _s) {
    if (!mod_ready()) return;
    sl_store_set_str(global.lua_state, _key, _s);
}

/// Close the Lua state and switch mods off (safe to call more than once).
function mod_shutdown() {
    if (variable_global_exists("lua_state") && global.lua_state >= 0) {
        try { sl_close(global.lua_state); } catch (_e) { /* ignore */ }
        global.lua_state = -1;
    }
    global.mods_enabled = false;
    mod_log("modloader shut down");
}

/// Deliberately hard-crashes the game (used by the crash-button test mod).
/// sl_dostring() casts its first arg to a lua_State* with no validation;
/// 0x1 lives in the always-unmapped null page, so the dereference SIGSEGVs.
/// Intentionally NOT wrapped in try/catch: a native signal isn't catchable,
/// and the whole point is for the process to die.
function mod_crash() {
    mod_log("crash button pressed - deliberately crashing");
    sl_dostring(1, "crash");
}

/// Draw every button a mod declared in the store and handle its click.
/// Store contract (set from Lua via swe.store_set):
///   btn.count          number of buttons
///   btn.<i>.enabled    1 = show, 0 = hide
///   btn.<i>.x/.y/.w/.h position + size in GUI coordinates
///   btn.<i>.label      text drawn on the button
///   btn.<i>.action     "crash" = hard-crash on click (others = no-op)
/// Called each frame from obj_persistent's Draw GUI event, so buttons are
/// always on screen, in every room, on top of everything.
function mod_ui_draw() {
    if (!mod_ready()) return;
    var _count = floor(mod_store_get_num("btn.count"));
    if (_count <= 0) return;
    if (_count > 8) _count = 8;

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _clicked = mouse_check_button_pressed(mb_left);

    if (variable_global_exists("font_google")) draw_set_font(global.font_google);
    draw_set_alpha(1);
    for (var _i = 0; _i < _count; _i++) {
        var _key = "btn." + string(_i) + ".";
        if (mod_store_get_num(_key + "enabled") < 1) continue;
        var _x = mod_store_get_num(_key + "x");
        var _y = mod_store_get_num(_key + "y");
        var _w = mod_store_get_num(_key + "w");
        var _h = mod_store_get_num(_key + "h");
        if (_w <= 0 || _h <= 0) continue;
        var _label = mod_store_get_str(_key + "label");
        var _action = mod_store_get_str(_key + "action");
        var _hover = (_mx >= _x && _mx <= (_x + _w) && _my >= _y && _my <= (_y + _h));

        // body + border
        draw_set_color(_hover ? c_red : c_dkgray);
        draw_rectangle(_x, _y, _x + _w, _y + _h, false);
        draw_set_color(c_white);
        draw_rectangle(_x, _y, _x + _w, _y + _h, true);
        draw_text((_x + 8), (_y + (_h / 2) - 8), _label);

        // click -> action
        if (_clicked && _hover) {
            if (_action == "crash") {
                mod_crash();
            } else {
                // generic: notify mods which button was pressed
                mod_arg_clear();
                mod_arg_str(0, _key);
                mod_arg_str(1, _action);
                mod_fire("on_button_click");
                mod_arg_clear();
            }
        }
    }
    draw_set_color(c_white);
}
