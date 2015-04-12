import std.stdio;

enum LogLevel {
  DEBUG = 0,
  INFO,
  ERROR,
  FATAL
}

LogLevel log_level = LogLevel.DEBUG;


void log(T...)(T args) {
  writeln(args);
}

void log_debug(T...)(T args) {
  if(log_level < LogLevel.INFO)
    writeln("DEBUG: ", args);
}

void log_info(T...)(T args) {
  if(log_level < LogLevel.ERROR)
    writeln("INFO: ", args);
}

void log_fatal(T...)(T args) {
    writeln("FATAL: ", args);
}
