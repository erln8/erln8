import std.stdio;
import std.typecons; // Nullable
import std.c.stdlib; // exit()
import std.path;
import std.process;
import std.getopt;
import std.file;
import std.format;
import std.string;

import config;
import dirconfig;
import dini;
import log;
import utils;
import builder;
import impl;

struct RebarBuildOptions {
  string repo;
  string tag;
  string id;
  string configname;
}

// executables to symlink to after a build is complete

string[] bins = [
  "rebar"
];


class ReoImpl : Impl {

    this() {
      IdKey = "Rebars";
      name = "reo";
      commands = ["rebar"];
      installbasedir = getConfigSubdir("rebars");
      repodir = getConfigSubdir("rebar_repos");
      appConfigName = "reo_config";
      IdKey = "Rebars";
    }

    override void initOnce() {
      log_debug("reo init once");
      writeln("First time initialization of reo");
      mkdirSafe(getConfigDir());
      mkdirSafe(buildNormalizedPath(getConfigDir(), "rebars"));
      mkdirSafe(buildNormalizedPath(getConfigDir(), "rebar_repos"));
      // create ~/.erln8.d
      // create ~/.erln8.d/otps/
      // create ~/.erln8.d/repos/

      // create ~/.erln8.d/config file
      File config = File(buildNormalizedPath(getConfigDir(), "reo_config"), "w");
      config.writeln(q"EOS
[Reo]
default_config=default
system_default=
color=true

[Repos]
default=https://github.com/rebar/rebar.git

[Rebars]
none=

[Configs]
EOS"
);
      config.close();
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
        log_fatal("Can't find a configured version of Rebar");
        exit(-1);
      }

      log_debug("Rebar id:", dirini["Config"].getKey("Rebar"));
      string rebarid = dirini["Config"].getKey("Rebar");
      if(!isValidRebar(cfg, rebarid)) {
        log_fatal("Unknown Rebar id: ", rebarid);
        exit(-1);
      }
      if(currentOpts.opt_show) {
        writeln(rebarid);
      } else {
        write(rebarid);
      }
    }

    void doUse(Ini cfg) {
      auto keys = cfg[IdKey].keys();
      log_debug("Trying to use ", currentOpts.opt_use);
      string rebarId = currentOpts.opt_use;
      if(!(rebarId in keys)) {
        writeln(rebarId, " is not a configured version of Rebar");
        exit(-1);
      }
      string fileName = "erln8.config";
      if(exists(fileName)) {
        if(!currentOpts.opt_force) {
          writeln("Config already exists in this directory. Override with --force.");
          exit(-1);
        }
      }

      // TODO: append to file
      File file = File("erln8.config", "w");
      file.writeln("[Config]");
      file.writeln("Rebar=", rebarId);
    }


    bool isValidRebar(Ini ini, string id) {
      return ini[IdKey].hasKey(id);
    }

    RebarBuildOptions getBuildOptions(string repo, string tag, string id, string configname) {
      RebarBuildOptions opts;
      opts.repo = (repo == null ? "default" : repo);
      opts.tag = tag;
      opts.id  = id;
      // TODO: use Rebar.default_config value here
      //opts.configname = (configname == null ? "default_config" : configname);
      opts.configname = configname;
      return opts;
    }

    void verifyInputs(Ini cfg, RebarBuildOptions build_options) {
      auto rebars = cfg[IdKey].keys();
      if(build_options.id in rebars) {
        writeln("A version of Rebar already exists with the id ", build_options.id);
        exit(-1);
      }

      auto repos = cfg["Repos"].keys();
      if(!(build_options.repo in repos)) {
        writeln("Unconfigured repo: ", build_options.repo);
        exit(-1);
      }

      string repoURL = cfg["Repos"].getKey(build_options.repo);
      string repoPath = buildNormalizedPath(getConfigSubdir(repodir),build_options.repo);

      if(!exists(repoPath)) {
        writeln("Missing repo for " ~ currentOpts.opt_fetch
            ~ ", which should be in " ~ repoPath ~ ". Maybe you forgot to reo --clone <repo_name>");
        exit(-1);
      }

      // TODO
      //auto configs = cfg["Configs"].keys();
      //if(!(build_options.configname in configs)) {
      //  writeln("Unknown build config: ", build_options.configname);
      //  exit(-1);
      // }

    }

    void checkObject(RebarBuildOptions opts, string sourcePath) {
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
      RebarBuildOptions opts = getBuildOptions(currentOpts.opt_repo,
          currentOpts.opt_tag,
          currentOpts.opt_id,
          currentOpts.opt_config);

      verifyInputs(cfg, opts);

      string outputRoot = buildNormalizedPath(getConfigSubdir("otps"),opts.id);
      string outputPath = buildNormalizedPath(outputRoot, "dist");
      string sourcePath = buildNormalizedPath(getConfigSubdir(repodir), opts.repo);

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

      string cmd1 = format("%s cd %s && ./bootstrap > ./build_log 2>&1",
          env, tmp);

      Builder b = new Builder();
      b.addCommand("Copy source          ", cmd0);
      b.addCommand("bootstrap            ", cmd1);

      // TODO: build plt
      if(!b.run()) {
        writeln("*** Build failed ***");
        writeln("Here are the last 10 lines of " ~ logFile);
        auto pid = spawnShell("tail -10 " ~ logFile);
        wait(pid);
        return;
      }
      log_debug("Adding Rebar id to ~/.erln8/reo_config");
      cfg[IdKey].setKey(opts.id, outputPath);
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
        log_fatal("Can't find a configured version of Rebar");
        exit(-1);
      }

      log_debug("Rebar id:", dirini["Config"].getKey("Rebar"));
      string rebarId = dirini["Config"].getKey("Rebar");
      if(!isValidRebar(cfg, rebarId)) {
        log_fatal("Unknown Rebar id: ", rebarId);
        exit(-1);
      }
      log_debug("installbasedir = ", installbasedir);
      log_debug("repodir = ", repodir);

      string binFullPath = buildNormalizedPath(installbasedir, rebarId, bin);
      log_debug("mapped cmd to execute = ", binFullPath);
      auto argsPassthrough = [bin] ~ cmdline[1 .. $];
      log_debug("Args = ", argsPassthrough);
      execv(binFullPath, argsPassthrough);
    }

}



