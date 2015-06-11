import std.path;
import std.file;
import std.stdio;
import std.regex;
import std.c.stdlib; // exit()
import std.process;
import std.format;
import std.string;
import std.getopt;

import config;
import dini;
import log;
import utils;

enum RemoteOption { none, add, remove, show };

struct CommandLineOptions {
  string opt_use       = null;
  bool   opt_list      = false;
  string opt_clone     = null;
  string opt_fetch     = null;
  bool   opt_build     = false;
  string opt_repo      = null;
  string opt_tag       = null;
  string opt_id        = null;
  string opt_config    = null;
  bool   opt_show      = false;
  bool   opt_prompt    = false;
  bool   opt_configs   = false;
  bool   opt_repos     = false;
  bool   opt_link      = false;
  bool   opt_unlink    = false;
  bool   opt_force     = false;
  bool   opt_nocolor   = false;
  bool   opt_buildable = false;
  bool   opt_debug     = false;
  RemoteOption opt_remote = RemoteOption.none;
  string[] allargs;
}

class Impl {
  CommandLineOptions currentOpts;
  string name;
  string[] commands;

  string IdKey;           // cfg["Erlangs"], cfg["Rebars"] etc
  string installbasedir;  // where the compiled packages live
  string repodir;         // where erln8/reo keeps this impls git repo
  string appConfigName;   // ~/.erln8.d/foo_config

  abstract void initOnce();

  abstract void runCommand(string[] cmdline);
  abstract void runConfig();
  abstract string[] getSymlinkedExecutables();


  void processArgs(string[] args) {
    CommandLineOptions opts;
    auto rslt = getopt(
      args,
      "use",       "Setup the current directory to use a specific verion of Erlang", &opts.opt_use,
      "list",      "List available Erlang installations",      &opts.opt_list,
      "remote",    "add/delete/show remotes", &opts.opt_remote,
      "clone",     "Clone an Erlang source repository",  &opts.opt_clone,
      "fetch",     "Update source repos",  &opts.opt_fetch,
      "build",     "Build a specific version of OTP from source",  &opts.opt_build,
      "repo",      "Specifies repo name to build from",  &opts.opt_repo,
      "tag",       "Specifies repo branch/tag to build fro,",  &opts.opt_tag,
      "id",        "A user assigned name for a version of Erlang",  &opts.opt_id,
      "config",    "Build configuration",  &opts.opt_config,
      "show",      "Show the configured version of Erlang in the current working directory",  &opts.opt_show,
      "prompt",    "Display the version of Erlang configured for this part of the directory tree",  &opts.opt_prompt,
      "configs",   "List build configs",  &opts.opt_configs,
      "repos",     "List build repos",  &opts.opt_repos,
      "link",      "Link a non-erln8 build of Erlang to erln8",  &opts.opt_link,
      "unlink",    "Unlink a non-erln8 build of Erlang from erln8",  &opts.opt_unlink,
      "force",     "Overwrite an erln8.config in the current directory",  &opts.opt_force,
      "nocolor",   "Don't use color output",  &opts.opt_nocolor,
      "buildable", "List tags to build from configured source repos", &opts.opt_buildable,
      "debug",     "Show debug output", &opts.opt_debug
        );
    if(rslt.helpWanted) {
      defaultGetoptPrinter(name, rslt.options);
      exit(0);
    }
    log_debug(opts);
    opts.allargs = args;
    currentOpts = opts;
  }

  void setupBins() {
      auto binPath = buildNormalizedPath(getConfigDir(), "bin");
      writeln("PLEASE ADD ", binPath, " TO YOUR PATH");
      mkdirSafe(binPath);
      foreach(bin;getSymlinkedExecutables()) {
          auto linkTo = buildNormalizedPath(binPath, baseName(bin));
          symlink(thisExePath(), linkTo);
      }
  }


  Ini getAppConfig() {
    string cfgFileName = buildNormalizedPath(getConfigDir(), appConfigName);
    log_debug("Attempting to load ", cfgFileName);
    if(!exists(cfgFileName)) {
      log_fatal(name ~ "has not been initialized");
      exit(-1);
    }
    Ini ini = Ini.Parse(cfgFileName);
    return ini;
  }

  void saveAppConfig(Ini cfg) {
    string cfgFileName = buildNormalizedPath(getConfigDir(), appConfigName);
    log_debug("Attempting to save ", cfgFileName);
    if(!exists(cfgFileName)) {
      log_fatal("erln8 has not been initialized");
      exit(-1);
    }

    File output = File(cfgFileName, "w");
    foreach(section;cfg.sections) {
      auto keys = cfg[section.name].keys();
      output.writeln("[" ~ section.name ~ "]");
      foreach(k,v;keys) {
        output.writeln(k, "=", v);
      }
      output.writeln("");
    }
  }


  void init() {
    if(exists(buildNormalizedPath(getConfigDir(), appConfigName))) {
      log_debug(name ~ " has already been initialized");
      return;
    } else {
      initOnce();
    }
  }

  void mkdirSafe(string d) {
    try {
      mkdir(d);
    } catch(FileException fe) {
      auto ctr = ctRegex!(`File exists`);
      auto c2 = matchFirst(fe.msg, ctr);
      if(c2.empty) {
        writeln(fe.msg);
        throw fe;
      } else {
        log_debug("File already exists: ", d);
      }
    }
  }

  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }

  void doBuildable(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      log_debug("Listing buildable in repo ", k, " @ ", v);

      string currentRepoDir = buildNormalizedPath(repodir, k);
      log_debug(currentRepoDir);
      string cmd = "cd " ~ currentRepoDir ~ " && git tag | sort | pr -3 -t";
      log_debug(cmd);
      auto pid = spawnShell(cmd);
      wait(pid);
    }
  }

  void doList(Ini cfg) {
    auto keys = cfg[IdKey].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      writeln(k, " -> ", v);
    }
  }

  void doRepos(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    foreach(k,v;keys) {
      writeln(k," -> ", v);
    }
  }

  void doConfigs(Ini cfg) {
    auto keys = cfg["Configs"].keys();
    foreach(k,v;keys) {
      writeln(k," -> ", v);
    }
  }

  void doClone(Ini cfg) {
    doClone(cfg, currentOpts.opt_clone);
  }

  void doClone(Ini cfg, string name) {
      auto keys = cfg["Repos"].keys();
      if(!(name in keys)) {
        writeln("Unknown repo:", name);
        exit(-1);
      }
      string repoURL = cfg["Repos"].getKey(name);
      string dest = buildNormalizedPath(getConfigSubdir(repodir),name);
      string command = "git clone " ~ repoURL ~ " " ~ dest;
      log_debug(command);
      auto pid = spawnShell(command);
      wait(pid);
  }

  void doFetch(Ini cfg) {
      auto keys = cfg["Repos"].keys();
      if(!(currentOpts.opt_fetch in keys)) {
        writeln("Unknown repo:", currentOpts.opt_fetch);
        exit(-1);
      }
      string repoURL = cfg["Repos"].getKey(currentOpts.opt_fetch);
      string dest = buildNormalizedPath(getConfigSubdir(repodir),currentOpts.opt_fetch);

      if(!exists(dest)) {
        writeln("Missing repo for " ~ currentOpts.opt_fetch
            ~ ", which should be in " ~ dest ~ ". Maybe you forgot to reo --clone <repo_name>");
        exit(-1);
      }
      string command = "cd " ~ dest ~ "  && git fetch --all";
      log_debug(command);
      auto pid = spawnShell(command);
      wait(pid);
  }

  void doRemote(Ini cfg) {
      if(currentOpts.opt_remote == RemoteOption.show) {
          auto keys = cfg["Repos"].keys();
          foreach(k,v;keys) {
            writeln(k, " -> ", v);
          }
          exit(0);
        }

      if(currentOpts.opt_remote == RemoteOption.add ||
         currentOpts.opt_remote == RemoteOption.remove) {
        // processing the args removes them from the array
        
         if(currentOpts.opt_remote == RemoteOption.add) {
          if(currentOpts.allargs.length != 3) {
            writeln("Invalid arguments specified");
            exit(-1);
          }
        
          string name = currentOpts.allargs[$-2];
          string url  = currentOpts.allargs[$-1];
          writeln("Adding remote ", name, " -> ", url);
          cfg["Repos"].setKey(name, url);
          saveAppConfig(cfg);  
          exit(0);
        } else if(currentOpts.opt_remote == RemoteOption.remove) {
          if(currentOpts.allargs.length != 2) {
            writeln("Invalid arguments specified");
            exit(-1);
          }

          string name = currentOpts.allargs[$-1];
          cfg["Repos"].removeKey(name);
          writeln("Removing remote ", name);
          saveAppConfig(cfg);            
          exit(0);
        }


      }
      
      //string currentRepoDir = buildNormalizedPath(repodir
      //cfg["Erlangs"].setKey(opts.id, outputPath);
      //saveAppConfig(cfg);
  }

}
