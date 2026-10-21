{
  "resourceType": "GMExtension",
  "resourceVersion": "1.2",
  "name": "swe_lua",
  "androidactivityinject": "",
  "androidclassname": "",
  "androidcodeinjection": "",
  "androidinject": "",
  "androidmanifestinject": "",
  "androidPermissions": [],
  "androidProps": false,
  "androidsourcedir": "",
  "author": "",
  "classname": "",
  "copyToTargets": 194,
  "date": "2026-10-19T00:00:00.0000000-05:00",
  "description": "SMM:WE Lua modloader (Windows x64 + Linux x64). Lua 5.4 built into libslua.so / swe_lua_x64.dll.",
  "exportToGame": true,
  "extensionVersion": "1.0.0",
  "files": [
    {
      "resourceType": "GMExtensionFile",
      "resourceVersion": "1.0",
      "constants": [],
      "copyToTargets": 194,
      "filename": "swe_lua.dll",
      "final": "",
      "functions": [
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_newstate",
          "argCount": 0,
          "args": [],
          "documentation": "creates a new Lua state (returns it as a double handle)",
          "externalName": "sl_newstate",
          "help": "sl_newstate()",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_openlibs",
          "argCount": 0,
          "args": [
            2
          ],
          "documentation": "opens the standard Lua libraries",
          "externalName": "sl_openlibs",
          "help": "sl_openlibs(L)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_close",
          "argCount": 0,
          "args": [
            2
          ],
          "documentation": "closes a Lua state",
          "externalName": "sl_close",
          "help": "sl_close(L)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_dostring",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "loads + runs a Lua string; returns status (0 ok, else error code)",
          "externalName": "sl_dostring",
          "help": "sl_dostring(L, code)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_lasterror",
          "argCount": 0,
          "args": [],
          "documentation": "last error string from the last Lua call (static buffer)",
          "externalName": "sl_lasterror",
          "help": "sl_lasterror()",
          "hidden": false,
          "kind": 1,
          "returnType": 1
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_setglobal_num",
          "argCount": 0,
          "args": [
            2,
            1,
            2
          ],
          "documentation": "sets a global number",
          "externalName": "sl_setglobal_num",
          "help": "sl_setglobal_num(L, name, v)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_setglobal_str",
          "argCount": 0,
          "args": [
            2,
            1,
            1
          ],
          "documentation": "sets a global string",
          "externalName": "sl_setglobal_str",
          "help": "sl_setglobal_str(L, name, v)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_getglobal_type",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "type of a global (LUA_TNONE=-1, nil=0, bool=1, num=3, string=4, table=5, func=6)",
          "externalName": "sl_getglobal_type",
          "help": "sl_getglobal_type(L, name)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_getglobal_num",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "global number, 0 if not a number",
          "externalName": "sl_getglobal_num",
          "help": "sl_getglobal_num(L, name)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_getglobal_str",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "global string (empty if not a string)",
          "externalName": "sl_getglobal_str",
          "help": "sl_getglobal_str(L, name)",
          "hidden": false,
          "kind": 1,
          "returnType": 1
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_arg_clear",
          "argCount": 0,
          "args": [],
          "documentation": "clears the staged call argument list",
          "externalName": "sl_arg_clear",
          "help": "sl_arg_clear()",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_arg_num",
          "argCount": 0,
          "args": [
            2,
            2
          ],
          "documentation": "stages a numeric argument (0-based index)",
          "externalName": "sl_arg_num",
          "help": "sl_arg_num(i, v)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_arg_str",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "stages a string argument (0-based index)",
          "externalName": "sl_arg_str",
          "help": "sl_arg_str(i, s)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_pcall",
          "argCount": 0,
          "args": [
            2,
            1,
            2
          ],
          "documentation": "calls global function fname with argc staged arguments (0=success)",
          "externalName": "sl_pcall",
          "help": "sl_pcall(L, fname, argc)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_result_type",
          "argCount": 0,
          "args": [],
          "documentation": "result type of the last sl_pcall (see sl_getglobal_type)",
          "externalName": "sl_result_type",
          "help": "sl_result_type()",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_result_num",
          "argCount": 0,
          "args": [],
          "documentation": "numeric result of the last sl_pcall",
          "externalName": "sl_result_num",
          "help": "sl_result_num()",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_result_str",
          "argCount": 0,
          "args": [],
          "documentation": "string result of the last sl_pcall (empty if not a string)",
          "externalName": "sl_result_str",
          "help": "sl_result_str()",
          "hidden": false,
          "kind": 1,
          "returnType": 1
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_fire",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "fires all hooks in __hooks[evname] with the staged arguments; returns ok count, or -n if n callbacks threw; errors are in sl_lasterror()",
          "externalName": "sl_fire",
          "help": "sl_fire(L, evname)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_store_set_num",
          "argCount": 0,
          "args": [
            2,
            1,
            2
          ],
          "documentation": "sl_store_set_num(key, value): write a number into the mod store",
          "externalName": "sl_store_set_num",
          "help": "sl_store_set_num(key, v)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_store_set_str",
          "argCount": 0,
          "args": [
            2,
            1,
            1
          ],
          "documentation": "sl_store_set_str(key, value): write a string into the mod store",
          "externalName": "sl_store_set_str",
          "help": "sl_store_set_str(key, v)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_store_get_type",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "type of a mod-store key (see sl_getglobal_type)",
          "externalName": "sl_store_get_type",
          "help": "sl_store_get_type(key)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_store_get_num",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "mod-store number, 0 if not a number",
          "externalName": "sl_store_get_num",
          "help": "sl_store_get_num(key)",
          "hidden": false,
          "kind": 1,
          "returnType": 2
        },
        {
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "1.0",
          "name": "sl_store_get_str",
          "argCount": 0,
          "args": [
            2,
            1
          ],
          "documentation": "mod-store string (empty if not a string)",
          "externalName": "sl_store_get_str",
          "help": "sl_store_get_str(key)",
          "hidden": false,
          "kind": 1,
          "returnType": 1
        }
      ],
      "init": "",
      "kind": 1,
      "order": [
        {"name":"sl_newstate","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_openlibs","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_close","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_dostring","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_lasterror","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_setglobal_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_setglobal_str","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_getglobal_type","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_getglobal_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_getglobal_str","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_arg_clear","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_arg_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_arg_str","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_pcall","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_result_type","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_result_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_result_str","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_fire","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_store_set_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_store_set_str","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_store_get_type","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_store_get_num","path":"extensions/swe_lua/swe_lua.yy"},
        {"name":"sl_store_get_str","path":"extensions/swe_lua/swe_lua.yy"}
      ],
      "origname": "",
      "ProxyFiles": [
        {
          "resourceType": "GMProxyFile",
          "resourceVersion": "1.0",
          "name": "libswe_lua.so",
          "TargetMask": 7
        },
        {
          "resourceType": "GMProxyFile",
          "resourceVersion": "1.0",
          "name": "swe_lua_x64.dll",
          "TargetMask": 6
        }
      ],
      "uncompress": false,
      "usesRunnerInterface": false
    }
  ],
  "gradleinject": "",
  "hasConvertedCodeInjection": false,
  "helpfile": "",
  "HTML5CodeInjection": "",
  "html5Props": false,
  "IncludedResources": [],
  "installdir": "",
  "iosCocoaPodDependencies": "",
  "iosCocoaPods": "",
  "ioscodeinjection": "",
  "iosdelegatename": "",
  "iosplistinject": "",
  "iosProps": false,
  "iosSystemFrameworkEntries": [],
  "iosThirdPartyFrameworkEntries": [],
  "license": "",
  "maccompilerflags": "",
  "maclinkerflags": "",
  "macsourcedir": "",
  "options": [],
  "optionsFile": "options.json",
  "packageId": "",
  "parent": {
    "name": "Extensions",
    "path": "folders/Extensions.yy"
  },
  "productId": "",
  "sourcedir": "",
  "supportedTargets": -1,
  "tvosclassname": null,
  "tvosCocoaPodDependencies": "",
  "tvosCocoaPods": "",
  "tvoscodeinjection": "",
  "tvosdelegatename": null,
  "tvosmaccompilerflags": "",
  "tvosmaclinkerflags": "",
  "tvosplistinject": "",
  "tvosProps": false,
  "tvosSystemFrameworkEntries": [],
  "tvosThirdPartyFrameworkEntries": []
}
