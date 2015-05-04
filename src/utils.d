import std.stdio;
import std.datetime;
import std.array;
import std.string;
import std.conv;

string getTimestampedFilename() {
  auto currentTime = Clock.currTime();
  auto timeString = currentTime.toISOExtString();
  return timeString.replace("-","_").replace(":","_").replace(".", "_");
}

bool askSomething(string q) {
  char resp;
  write(q);
  readf("%c", &resp);
  string x = to!string(resp).toLower();
  if(x == "y") {
    return true;
  } else {
    return false;
  }
}
