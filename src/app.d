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

import dini; // ini parser

import spinner;
import log;
import options;
import impl;
import config;
import dirconfig;

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
  log_debug("Finished registering impl ", i.name);
}

void main(string[] args) {


//  foreach (DirEntry de; dirEntries("/Users/dparfitt/.erln8.d/otps/foo/dist/bin", SpanMode.depth))
//  {
//    if(de.isFile()) {
//      if(de.attributes() == 33261) {
//        writeln(baseName(de.name), " -> ", de);
//      }
//    }
//  }
//
  log_debug("erln8 args:", args);
  erln8_home = defaultHome();
  writeln("erln8 v2");

  registerImpl(new Erln8Impl());

  string binname = baseName(args[0]);
  if(binname in impls) {
    log_debug("Using config impl:", binname);
    Impl impl = impls[binname];
    impl.processArgs(args);
    impl.runConfig();
  } else if(binname in implCommands) {
    log_debug("Using command impl:", binname);
    Impl impl = implCommands[binname];
    impl.processArgs(args);
    impl.runCommand(args);
  } else {
    log_fatal("Unknown command: ", binname);
    exit(-1);
  }
}

//  try {
//     getOptions(args);
//
//  } catch(GetOptException e) {
//    log_fatal(e.msg);
//    exit(-1);
//  }
//  if (helpInformation.helpWanted) {
//      writeln("erln8",
//        helpInformation.options);
//    }


