import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;
import std.file;
import std.format;
import std.string;
import std.algorithm.iteration;

import config;
import dirconfig;
import dini;
import log;
import utils;
import builder;
import impl;

struct ErlangBuildOptions {
  string repo;
  string tag;
  string id;
  string configname;
}

// executables to symlink to after a build is complete

string[] bins = [
  "bin/ct_run",
  "bin/dialyzer",
  "bin/epmd",
  "bin/erl",
  "bin/erlc",
  "bin/escript",
  "bin/run_erl",
  "bin/run_test",
  "bin/to_erl",
  "bin/typer",
  "lib/erlang/lib/diameter-*/bin/diameterc",
  "lib/erlang/lib/edoc-*/priv/edoc_generate",
  "lib/erlang/lib/erl_interface-*/bin/erl_call",
  "lib/erlang/lib/inets-*/priv/bin/runcgi.sh",
  "lib/erlang/lib/observer-*/priv/bin/cdv",
  "lib/erlang/lib/observer-*/priv/bin/etop",
  "lib/erlang/lib/odbc-*/priv/bin/odbcserver",
  "lib/erlang/lib/os_mon-*/priv/bin/memsup",
  "lib/erlang/lib/snmp-*/bin/snmpc",
  "lib/erlang/lib/tools-*/bin/emem",
  "lib/erlang/lib/webtool-*/priv/bin/start_webtool"
  ];


  class Erln8Impl : Impl {

    this() {
      name = "erln8";
      commands = [];
      foreach(b;bins) {
        commands ~= baseName(b);
      }

      installbasedir = getConfigSubdir("otps");
      repodir = getConfigSubdir("repos");
      appConfigName = "config";
      IdKey = "Erlangs";
    }

    override void initOnce() {
      if(exists(buildNormalizedPath(getConfigDir(), appConfigName))) {
        log_debug("Erln8 has already been initialized");
        return;
      }

      log_debug("Erln8 init once");
      writeln("First time initialization of erln8");
      mkdirSafe(getConfigDir());
      mkdirSafe(buildNormalizedPath(getConfigDir(), "otps"));
      mkdirSafe(buildNormalizedPath(getConfigDir(), "repos"));
      // create ~/.erln8.d
      // create ~/.erln8.d/otps/
      // create ~/.erln8.d/repos/

      // create ~/.erln8.d/config file
      File config = File(buildNormalizedPath(getConfigDir(), "config"), "w");
      
      //https://github.com/erlang/otp.git
string cfgfileout = format("     
[Erln8]
default_config=default
system_default=
color=true

[Repos]
default=%s

[Erlangs]
none=

[Configs]
osx_gcc=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit
default=
osx_llvm=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit
osx_llvm_dtrace=--disable-hipe --enable-smp-support --enable-threads --enable-kernel-poll --enable-darwin-64bit --enable-vm-probes --with-dynamic-trace=dtrace
osx_gcc_env=CC=gcc-4.2 CPPFLAGS='-DNDEBUG' MAKEFLAGS='-j 3'k
", getDefaultOTPUrl());

      config.writeln(cfgfileout);
      config.close();      

      setupBins();

      Ini cfg = getAppConfig();
      doClone(cfg, "default");
    }



    override string[] getSymlinkedExecutables() {
      string[] all = [];
      foreach(bin;bins) {
        all = all ~ baseName(bin);
      }
      return all;
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



    void setupLinks(string root) {
      foreach(bin;bins) {
        string base = baseName(bin);
        if(bin.indexOf('*') >= 0) {
          // paths that include a *
          string p = buildNormalizedPath(root, "dist", bin);
          log_debug("Getting full path of ", p);
          log_debug("  basename = ", base);
          auto ls = executeShell("ls " ~ p);
          if (ls.status != 0) {
            writeln("Failed to find file while creating symlink: ", p);
            // keep going, maybe a command has been removed?
          } else {
            if(splitLines(ls.output).length > 1) {
              log_fatal("Found more than 1 executable for ", p , " while creating symlinks");
              exit(-1);
            }
            string fullpath = strip(splitLines(ls.output)[0]);
            string linkTo = buildNormalizedPath(root, base);
            log_debug("Found ", fullpath);
            log_debug("symlink ", fullpath, " to ", linkTo);
            symlink(fullpath, linkTo);
          }
        } else {
          // paths that do not include a *
          string fullpath = buildNormalizedPath(root, "dist", bin);
          string linkTo = buildNormalizedPath(root, base);
          log_debug("symlink ", fullpath, " to ", linkTo);
          symlink(fullpath, linkTo);
        }
      }
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

      log_debug("Output root = ", outputRoot);
      log_debug("Output path = ", outputPath);
      log_debug("Source path = ", sourcePath);

      string tmp = buildNormalizedPath(tempDir(), getTimestampedFilename());
      log_debug("tmp dir = ", tmp);
      string logFile = buildNormalizedPath(tmp, "build_log");
      log_debug("log = ", tmp);

      mkdirRecurse(tmp);

      string cmd0 = format("%s cd %s && git archive %s | (cd %s; tar -f - -x)",
          env,  sourcePath,     opts.tag, tmp);

      string cmd1 = format("%s cd %s && ./otp_build autoconf > ./build_log 2>&1",
          env, tmp);
      string cmd2 = format("%s cd %s && ./configure --prefix=%s %s >> ./build_log 2>&1",
          env, tmp, outputPath, ""); // TODO buildconfig

      // TODO: configurable parallelism
      string cmd3 = format("%s cd %s && %s -j4 >> ./build_log 2>&1",
          env, tmp, makeBin);

      string cmd4 = format("%s cd %s && %s install >> ./build_log 2>&1",
          env, tmp, makeBin);

      string cmd5 = format("%s cd %s && %s install-docs >> ./build_log 2>&1",
          env, tmp, makeBin);

      Builder b = new Builder();
      b.addCommand("Copy source          ", cmd0);
      b.addCommand("opt_build            ", cmd1);
      b.addCommand("configure            ", cmd2);
      b.addCommand("make                 ", cmd3);
      b.addCommand("make install         ", cmd4);
      b.addCommand("make install-docs    ", cmd4);
      // TODO: build plt
      if(!b.run()) {
        writeln("*** Build failed ***");
        writeln("Here are the last 10 lines of " ~ logFile);
        auto pid = spawnShell("tail -10 " ~ logFile);
        wait(pid);
        return;
      }
      log_debug("Adding Erlang id to ~/.erln8/config");
      cfg["Erlangs"].setKey(opts.id, outputPath);
      saveAppConfig(cfg);
      setupLinks(outputRoot);

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
      } else if(currentOpts.opt_remote != RemoteOption.none) {
        doRemote(cfg);
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



