import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;
import std.file;
import std.format;

import config;
import dirconfig;
import dini;
import log;
import spinner;

class Impl {
  string name;
  string[] commands;
  string installbasedir;  // where the compiled package lives in erln8
  string repodir;         // where erln8/reo keeps this impls git repo

  //abstract void initOnce(Ini initialIni);

  abstract void processArgs(string args[]);
  abstract void runCommand(string[] cmdline);
  abstract void runConfig();

  string getConfigSubdir(string subdir) {
    return expandTilde(buildNormalizedPath(getConfigDir(), subdir));
  }
}


struct Erln8Options {
  bool   opt_init      = false;
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
}

struct ErlangBuildOptions {
  string repo;
  string tag;
  string id;
  string configname;
}

class Erln8Impl : Impl {
  Erln8Options currentOpts;

  this() {
    name = "erln8";
    commands = ["erlc"];
    installbasedir = getConfigSubdir("otps");
    repodir = getConfigSubdir("repos");
  }

  override void processArgs(string args[]) {
    Erln8Options opts;
    auto rslt = getopt(
            args,
            "init",      &opts.opt_init,
            "use",       &opts.opt_use,
            "list",      &opts.opt_list,
            "clone",     &opts.opt_clone,
            "fetch",     &opts.opt_fetch,
            "build",     &opts.opt_build,
            "repo",      &opts.opt_repo,
            "tag",       &opts.opt_tag,
            "id",        &opts.opt_id,
            "config",    &opts.opt_config,
            "show",      &opts.opt_show,
            "prompt",    &opts.opt_prompt,
            "configs",   &opts.opt_configs,
            "repos",     &opts.opt_repos,
            "link",      &opts.opt_link,
            "unlink",    &opts.opt_unlink,
            "force",     &opts.opt_force,
            "nocolor",   &opts.opt_nocolor,
            "buildable", &opts.opt_buildable,
            "debug",     &opts.opt_debug
            );

      if(rslt.helpWanted) {
        defaultGetoptPrinter("erln8", rslt.options);
      }
    log_debug(opts);
    currentOpts = opts;
  }

  void doBuildable(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      log_debug("Listing buildable in repo ", k, " @ ", v);

      string currentRepoDir = buildNormalizedPath(repodir, k);
      log_debug(currentRepoDir);
      string cmd = "cd " ~ currentRepoDir ~ " && git tag | sort";
      log_debug(cmd);
      auto pid = spawnShell(cmd);
      wait(pid);
    }
  }

  void doList(Ini cfg) {
    auto keys = cfg["Erlangs"].keys();
    log_debug(keys);
    foreach(k,v;keys) {
      writeln(k, " -> ", v);
    }
  }

  void doShow(Ini cfg) {
    Nullable!Ini dirini = getConfigFromCWD();
    if(dirini.isNull) {
      log_fatal("Can't find a configured version of Erlang");
      exit(-1);
    }

    log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
    string erlid = dirini["Config"].getKey("Erlang");
    if(!isValidErlang(cfg, erlid)) {
      log_fatal("Unknown Erlang id: ", erlid);
      exit(-1);
    }
    if(currentOpts.opt_show) {
      writeln(erlid);
    } else {
      write(erlid);
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

  void doUse(Ini cfg) {
    auto keys = cfg["Erlangs"].keys();
    log_debug("Trying to use ", currentOpts.opt_use);
    string erlangId = currentOpts.opt_use;
    if(!(erlangId in keys)) {
      writeln(erlangId, " is not a configured version of Erlang");
      exit(-1);
    }
    string fileName = "erln8.config";
    if(exists(fileName)) {
      if(!currentOpts.opt_force) {
        writeln("Config already exists in this directory. Override with --force.");
        exit(-1);
      }
    }

    File file = File("erln8.config", "w");
    file.writeln("[Config]");
    file.writeln("Erlang=", erlangId);
  }

  void doClone(Ini cfg) {
    auto keys = cfg["Repos"].keys();
    if(!(currentOpts.opt_clone in keys)) {
      writeln("Unknown repo:", currentOpts.opt_clone);
      exit(-1);
    }
    string repoURL = cfg["Repos"].getKey(currentOpts.opt_clone);
    string dest = buildNormalizedPath(getConfigSubdir("repos"),currentOpts.opt_clone);
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
    string dest = buildNormalizedPath(getConfigSubdir("repos"),currentOpts.opt_fetch);

    if(!exists(dest)) {
      writeln("Missing repo for " ~ currentOpts.opt_fetch
          ~ ", which should be in " ~ dest ~ ". Maybe you forgot to erln8 --clone <repo_name>");
      exit(-1);
    }
    string command = "cd " ~ dest ~ "  && git fetch --all";
    log_debug(command);
    auto pid = spawnShell(command);
    wait(pid);
  }

 

  bool isValidErlang(Ini ini, string id) {
    return ini["Erlangs"].hasKey(id);
  }





  ErlangBuildOptions getBuildOptions(string repo, string tag, string id, string configname) {
    ErlangBuildOptions opts;
    opts.repo = (repo == null ? "default" : repo);
    opts.tag = tag;
    opts.id  = id;
    // TODO: use Erlang.default_config value here
    //opts.configname = (configname == null ? "default_config" : configname);
    opts.configname = configname;
    return opts;
  }

  void verifyInputs(Ini cfg, ErlangBuildOptions build_options) {
    auto erlangs = cfg["Erlangs"].keys();
    if(build_options.id in erlangs) {
      writeln("A version of Erlang already exists with the id ", build_options.id);
      exit(-1);
    }

    auto repos = cfg["Repos"].keys();
    if(!(build_options.repo in repos)) {
      writeln("Unconfigured repo: ", build_options.repo);
      exit(-1);
    }

    string repoURL = cfg["Repos"].getKey(build_options.repo);
    string repoPath = buildNormalizedPath(getConfigSubdir("repos"),build_options.repo);

    if(!exists(repoPath)) {
      writeln("Missing repo for " ~ currentOpts.opt_fetch
          ~ ", which should be in " ~ repoPath ~ ". Maybe you forgot to erln8 --clone <repo_name>");
      exit(-1);
    }

    // TODO
    //auto configs = cfg["Configs"].keys();
    //if(!(build_options.configname in configs)) {
    //  writeln("Unknown build config: ", build_options.configname);
    //  exit(-1);
    // }

  }

  void checkObject(ErlangBuildOptions opts, string sourcePath) {
    string checkObj = "cd " ~ sourcePath ~ " && git show-ref " ~ opts.tag ~ " > /dev/null";
    log_debug(checkObj);
    auto shell = executeShell(checkObj);
    if(shell.status != 0) {
      writeln("branch or tag " ~ opts.tag ~ " does not exist in " ~ opts.repo ~ " Git repo");
      log_debug("Git object missing");
      exit(-1);
    } else {
      log_debug("Git object exists");
    }
  }



class BuildCommand {
  this(string description, string command) {
    desc = description;
    cmd = command;
  }
  string desc;
  string cmd;
}


class Builder {

  void run() {
    int i = 0;
    foreach(bc;cmds) {
      Spinner spinner = new FastSpinner();
      log_debug("Running ", bc.cmd);
      write(format("[%d] %s ", i, bc.desc));

      spinner.start();
      auto p = executeShell(bc.cmd);
      spinner.stop();
      if(p.status != 0) {
        writeln("Failed");
        //g_error("Build error, please check the build logs for more details\n");
        return;
      }
      writeln("");
      i++;
    }

    // TODO: setup links
    // TODO: setup binaries
  }

  void addCommand(string desc, string cmd) {
    cmds = cmds ~ new BuildCommand(desc, cmd);
  }

  private:
  BuildCommand[] cmds = [];
}

  void doBuild(Ini cfg) {
    ErlangBuildOptions opts = getBuildOptions(currentOpts.opt_repo,
                                              currentOpts.opt_tag,
                                              currentOpts.opt_id,
                                              currentOpts.opt_config);

    verifyInputs(cfg, opts);

    string outputRoot = buildNormalizedPath(getConfigSubdir("otps"),opts.id);
    string outputPath = buildNormalizedPath(outputRoot, "dist");
    string sourcePath = buildNormalizedPath(getConfigSubdir("repos"), opts.repo);

    checkObject(opts, sourcePath);
    string makeBin = getMakeBin();

    // TODO: build config _env
    string env = "";

    log_debug("Output path = ", outputPath);
    log_debug("Source path = ", sourcePath);
    // TODO: logs!

    string tmp = tempDir();
    log_debug("tmp dir = ", tmp);
    log_debug("log dir = ", tmp);

    string cmd0 = format("%s cd %s && git archive %s | (cd %s; tar -f - -x)",
                          env,  sourcePath,     opts.tag, tmp);

    string cmd1 = format("%s cd %s && ./otp_build autoconf > ./build_log 2>&1",
                          env, tmp);
    string cmd2 = format("%s cd %s && ./configure --prefix=%s %s >> ./build_log 2>&1",
                          env, tmp, outputPath, ""); // TODO buildconfig

    string cmd3 = format("%s cd %s && %s >> ./build_log 2>&1",
                          env, tmp, makeBin);

    string cmd4 = format("%s cd %s && %s install >> ./build_log 2>&1",
                          env, tmp, makeBin);

    string cmd5 = format("%s cd %s && %s install-docs >> ./build_log 2>&1",
                          env, tmp, makeBin);

    Builder b = new Builder();
    b.addCommand("Copy source", cmd0);
    b.addCommand("opt_build", cmd1);
    b.addCommand("configure", cmd2);
    b.addCommand("make", cmd3);
    b.addCommand("make install", cmd4);
    b.addCommand("make install-docs", cmd4);
    // TODO: build plt
    b.run();
    log_debug("Adding Erlang id to erln8.config");
    cfg["Erlangs"].setKey(opts.id, outputPath);
    saveAppConfig(cfg);
    writeln("Done!");
  }

  override void runConfig() {
    // TODO: this has to go after init
    // TODO: don't pass cfg everywhere?
    Ini cfg = getAppConfig();
    if(currentOpts.opt_buildable) {
      doBuildable(cfg);
    } else if(currentOpts.opt_list) {
      doList(cfg);
    } else if(currentOpts.opt_repos) {
      doRepos(cfg);
    } else if(currentOpts.opt_show || currentOpts.opt_prompt) {
      doShow(cfg);
    } else if(currentOpts.opt_configs) {
      doConfigs(cfg);
    } else if(currentOpts.opt_use) {
      doUse(cfg);
    } else if(currentOpts.opt_clone) {
      doClone(cfg);
    } else if(currentOpts.opt_fetch) {
      doFetch(cfg);
    } else if(currentOpts.opt_build) {
      doBuild(cfg);
    } else {
      log_debug("Nothing to do");
    }
  }

  override void runCommand(string[] cmdline) {
    Ini cfg = getAppConfig();
    log_debug("Config:", cfg);
    log_debug("Running: ", cmdline);
    string bin = baseName(cmdline[0]);

    Nullable!Ini dirini = getConfigFromCWD();
    if(dirini.isNull) {
      log_fatal("Can't find a configured version of Erlang");
      exit(-1);
    }

    log_debug("Erlang id:", dirini["Config"].getKey("Erlang"));
    string erlid = dirini["Config"].getKey("Erlang");
    if(!isValidErlang(cfg, erlid)) {
      log_fatal("Unknown Erlang id: ", erlid);
      exit(-1);
    }
    log_debug("installbasedir = ", installbasedir);
    log_debug("repodir = ", repodir);

    string binFullPath = buildNormalizedPath(installbasedir, erlid, bin);
    log_debug("mapped cmd to execute = ", binFullPath);
    auto argsPassthrough = [bin] ~ cmdline[1 .. $];
    log_debug("Args = ", argsPassthrough);
    execv(binFullPath, argsPassthrough);
  }

}



