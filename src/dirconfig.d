import std.path;
import std.file;
import std.typecons; // Nullable

import dini;
import log;

Nullable!Ini getConfigFromCWD() {
  string cwd = getcwd();
  return getDirConfig(cwd);
}

//writeln(ini["Repos"].getKey["default"]);
//writeln(ini["Repos"].getKey("default"));

Nullable!Ini getDirConfig(string path) {
  if(path == rootName(path)) {
    log_debug("Got to root dir");
    Nullable!Ini result;
    return result;
  }
  string cfgFileName = buildNormalizedPath(path, "erln8.config");
  log_debug("Looking for config ", cfgFileName);
  if(exists(cfgFileName)) {
    log_debug("Found!");
    Ini ini = Ini.Parse(cfgFileName);
    Nullable!Ini result;
    result = ini;
    return result;
  } else {
    string parent = buildNormalizedPath(path ~ dirSeparator ~ "..");
    return getDirConfig(parent);
  }
}
