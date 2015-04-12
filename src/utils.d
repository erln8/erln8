import std.datetime;
import std.array;

string getTimestampedFilename() {
  auto currentTime = Clock.currTime();
  auto timeString = currentTime.toISOExtString();
  return timeString.replace("-","_").replace(":","_").replace(".", "_");
}
