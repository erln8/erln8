import std.path;

import config;
import dini;
import log;
import utils;

class Impl {
  string name;
  string[] commands;
  string installbasedir;  // where the compiled package lives in erln8
  string repodir;         // where erln8/reo keeps this impls git repo

  abstract void initOnce();

  abstract void processArgs(string[] args);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();
  abstract string[] getSymlinkedExecutables();
  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }
}

