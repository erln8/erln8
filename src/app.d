/*
  erln8/reo/reo3
  (c) 2015 Dave Parfitt
  diparfitt@gmail.com
  See LICENSE for licensing info.
/*
  required DMD 2.067+ for getopt support
*/


import std.stdio;
import std.string;
import std.process;
import std.getopt;
import std.c.stdlib; // exit()
import std.path;
import std.file; // exists()

import std.string;
import std.algorithm.searching;
import dini; // ini parser
import colorize : fg, color, cwriteln, cwritefln;

import spinner;
import log;
import impl;
import config;
import dirconfig;

import erln8impl;
import reoimpl;
import reo3impl;


string erln8_home;

Impl[string] impls;
Impl[string] implCommands;

void registerImpl(Impl i) {
  impls[i.name] = i;
  log_debug("Registering impl ", i.name);
  foreach(name; i.commands) {
    log_debug("Registering command ", i.name, ":", name);
    implCommands[name] = i;
  }
  log_debug("executables provided: ", i.getSymlinkedExecutables());
  log_debug("Finished registering impl ", i.name);
}


void registerImpls() {
  Erln8Impl e8 = new Erln8Impl();
  registerImpl(e8);

  ReoImpl reo = new ReoImpl();
  registerImpl(reo);

  Reo3Impl reo3 = new Reo3Impl();
  registerImpl(reo3);
}

void initImpls() {
  foreach(k,v; impls) {
    log_debug("Calling into on impl ", k);
    v.init();
  }
}


// LogLevel
//Erln8.log_level
LogLevel getLogLevel(Ini cfg) {
  try {
    string loglevel = cfg["Erln8"].getKey("log_level");
    if(loglevel == "error") {
      return LogLevel.ERROR;
    } else if(loglevel == "info") {
      return LogLevel.INFO;
    } else if(loglevel == "debug") {
      return LogLevel.DEBUG;
    } else {
      return LogLevel.ERROR;
    }
  } catch (Exception e) {
    return LogLevel.ERROR;
  }
}

void main(string[] args) {

  if(canFind(args, "--debug")) {
    log_level = LogLevel.DEBUG;
  } else {
    log_level = LogLevel.ERROR;
  }

  log_debug("log_level = ", log_level);

  log_debug("args:", args);
  erln8_home = defaultHome();
  registerImpls();
  string binname = baseName(args[0]);
  log_debug("binname = ", binname);
  log_debug(impls);
  log_debug(implCommands);
  if(binname in impls) {
    log_debug("Using config impl:", binname);
    Impl impl = impls[binname];
    impl.processArgs(args);
    impl.init();
    impl.runConfig();
  } else if(binname in implCommands) {
    log_debug("Using command impl:", binname);
    Impl impl = implCommands[binname];
    impl.processArgs(args);
    impl.init();
    if(getLogLevel(impl.getAppConfig()) == LogLevel.INFO) {
      // show a trace message that shows which binaries/params are being called
      string msg = impl.name ~ " running " ~ to!(string)(args);
      cwriteln(msg.color(fg.yellow));
    }
    impl.runCommand(args);
  } else {
    log_fatal("Unknown command: ", binname);
    exit(-1);
  }

}



