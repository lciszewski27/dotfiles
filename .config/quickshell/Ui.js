.pragma library

/*
 * Pure helpers shared by the ported Go modules.
 *
 * The original Go code lives in ~/Projects/Active/go-waybar and is reproduced
 * here as plain JavaScript so Quickshell can render the same text without
 * spawning the waybar-modules binary.
 */

function repeat(str, count) {
  var out = "";
  for (var i = 0; i < count; i++) out += str;
  return out;
}

// Go's utf8.RuneCountInString: Nerd Font glyphs outside the BMP are surrogate
// pairs in JS strings, so count code points rather than UTF-16 units.
function runeCount(str) {
  var n = 0;
  for (var i = 0; i < str.length; i++) {
    var c = str.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff && i + 1 < str.length) {
      var d = str.charCodeAt(i + 1);
      if (d >= 0xdc00 && d <= 0xdfff) i++;
    }
    n++;
  }
  return n;
}

function truncate(str, max) {
  if (runeCount(str) <= max) return str;
  var out = "";
  var n = 0;
  for (var i = 0; i < str.length && n < max; i++) {
    var c = str.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff && i + 1 < str.length) {
      var d = str.charCodeAt(i + 1);
      if (d >= 0xdc00 && d <= 0xdfff) {
        out += str.charAt(i) + str.charAt(i + 1);
        i++;
        n++;
        continue;
      }
    }
    out += str.charAt(i);
    n++;
  }
  return out;
}

// Port of utils/ui/table.go DrawTable.
function drawTable(title, content) {
  if (!content || content.length === 0) return "";

  var maxW = runeCount(title) + 4;
  for (var i = 0; i < content.length; i++) {
    var len = runeCount(content[i]);
    if (len > maxW) maxW = len;
  }
  maxW += 2;

  var titleLen = runeCount(title);
  var side = Math.floor((maxW - titleLen - 2) / 2);
  if (side < 1) side = 1;
  var right = maxW - side - titleLen - 2;

  var out = "╭" + repeat("─", side) + " " + title + " " + repeat("─", right) + "╮\n";
  for (var j = 0; j < content.length; j++) {
    var padding = maxW - runeCount(content[j]);
    out += "│ " + content[j] + repeat(" ", padding - 1) + "│\n";
  }
  out += "╰" + repeat("─", maxW) + "╯";
  return out;
}

function contains(str, needle) {
  return str.indexOf(needle) >= 0;
}

function firstField(line) {
  var fields = line.trim().split(/\s+/);
  return fields.length > 0 && fields[0] !== "" ? fields[0] : "";
}

function packageLines(text) {
  var out = [];
  var lines = text.trim().split("\n");
  for (var i = 0; i < lines.length; i++) {
    var name = firstField(lines[i]);
    if (name !== "") out.push(name);
  }
  return out;
}

/* ------------------------------------------------------------------------- *
 * Weather — port of modules/weather/weather.go (wttr.in, ?0qnT format)
 * ------------------------------------------------------------------------- */

function weatherIcon(desc) {
  var d = desc.trim().toLowerCase();
  if (contains(d, "thunder") || contains(d, "lightning")) return "";
  if (contains(d, "drizzle") || (contains(d, "rain") && contains(d, "light"))) return "";
  if (contains(d, "rain") && contains(d, "heavy")) return "";
  if (contains(d, "rain") || contains(d, "shower")) return "󰼳";
  if (contains(d, "snow") || contains(d, "sleet") || contains(d, "blizzard")) return "󰙿";
  if (contains(d, "fog") || contains(d, "mist") || contains(d, "haze")) return "󰖑";
  if (contains(d, "cloudy") && contains(d, "partly")) return "";
  if (contains(d, "cloudy") || contains(d, "overcast")) return "";
  if (contains(d, "clear") && (contains(d, "night") || contains(d, "evening"))) return "";
  if (contains(d, "clear") || contains(d, "sunny")) return "";
  return "󰖐";
}

function dataIcon(content) {
  if (contains(content, "°C") || contains(content, "°F")) return "";
  if (contains(content, "km/h") || contains(content, "mph") || contains(content, "m/s")) return "󰖝";
  if (contains(content, "km") && !contains(content, "km/h")) return "󰈈";
  if (contains(content, "mm") || contains(content, "inch")) return "󰖗";
  if (contains(content, "%") || contains(content, "humidity")) return "";
  if (contains(content, "hPa") || contains(content, "mbar") || contains(content, "pressure")) return "󰅟";
  return "";
}

function weatherTooltip(lines) {
  var city = "";
  var details = [];
  for (var i = 0; i < lines.length; i++) {
    if (i === 0) {
      city = " " + lines[i].trim();
      continue;
    }
    if (runeCount(lines[i]) <= 16) continue;
    var content = lines[i].slice(16).trim();
    if (content === "" || content === "km" || content === "mm") continue;
    details.push(dataIcon(content) + " " + content);
  }
  return details.length === 0 ? city : drawTable(city, details);
}

function parseWeather(body) {
  var lines = body.split("\n");
  if (lines.length < 4) return null;

  var desc = lines[2].slice(15).trim();
  var icon = weatherIcon(desc);

  var fields = lines[3].slice(15).trim().split(/\s+/);
  var temp = "";
  var unit = "";
  if (fields.length >= 2) {
    temp = fields[0];
    unit = fields[1];
  } else if (fields.length === 1) {
    temp = fields[0];
    unit = "°C";
  } else {
    return null;
  }

  return {
    text: icon + "  " + temp + unit,
    alt: temp + unit,
    tooltip: weatherTooltip(lines)
  };
}

/* ------------------------------------------------------------------------- *
 * Countdown — port of modules/countdown/countdown.go
 * ------------------------------------------------------------------------- */

function splitDuration(seconds) {
  var negative = seconds < 0;
  var total = Math.round(Math.abs(seconds));
  return {
    weeks: Math.floor(total / 604800),
    days: Math.floor((total % 604800) / 86400),
    hours: Math.floor((total % 86400) / 3600),
    minutes: Math.floor((total % 3600) / 60),
    seconds: total % 60,
    negative: negative,
    totalSeconds: total
  };
}

function plural(singular, n) {
  return n === 1 ? singular : singular + "s";
}

function pad2(n) {
  return n < 10 ? "0" + n : "" + n;
}

function totalString(ts, divisor, decimals) {
  var value = ts.totalSeconds / divisor;
  if (decimals === 0) return "" + Math.round(value);
  return value.toFixed(decimals);
}

function applyFormat(format, ts) {
  if (!format) format = "{d}d {H}h {M}m {S}s";
  var out = "";
  var i = 0;
  while (i < format.length) {
    if (format.charAt(i) === "{") {
      if (format.charAt(i + 1) === "{") {
        out += "{";
        i += 2;
        continue;
      }
      var end = format.indexOf("}", i + 1);
      if (end < 0) {
        out += format.charAt(i);
        i++;
        continue;
      }
      var token = format.slice(i + 1, end);
      var value = null;
      switch (token) {
        case "w": value = "" + ts.weeks; break;
        case "ww": value = pad2(ts.weeks); break;
        case "d": value = "" + ts.days; break;
        case "dd": value = pad2(ts.days); break;
        case "H": value = "" + ts.hours; break;
        case "HH": value = pad2(ts.hours); break;
        case "M": value = "" + ts.minutes; break;
        case "MM": value = pad2(ts.minutes); break;
        case "S": value = "" + ts.seconds; break;
        case "SS": value = pad2(ts.seconds); break;
        case "total-d": value = totalString(ts, 86400, 1); break;
        case "total-h": value = totalString(ts, 3600, 1); break;
        case "total-m": value = totalString(ts, 60, 0); break;
        case "total-s": value = totalString(ts, 1, 0); break;
        case "label-w": value = "week"; break;
        case "label-d": value = "day"; break;
        case "label-h": value = "hour"; break;
        case "label-m": value = "minute"; break;
        case "label-s": value = "second"; break;
        case "label-ws": value = plural("week", ts.weeks); break;
        case "label-ds": value = plural("day", ts.days); break;
        case "label-hs": value = plural("hour", ts.hours); break;
        case "label-ms": value = plural("minute", ts.minutes); break;
        case "label-ss": value = plural("second", ts.seconds); break;
        case "status":
          value = ts.negative ? "overdue" : (ts.totalSeconds === 0 ? "done" : "active");
          break;
        default: value = "{" + token + "}";
      }
      out += value;
      i = end + 1;
    } else if (format.charAt(i) === "}" && format.charAt(i + 1) === "}") {
      out += "}";
      i += 2;
    } else {
      out += format.charAt(i);
      i++;
    }
  }
  return out;
}

var presets = {
  "compact": "{dd}:{HH}:{MM}:{SS}",
  "default": "{d}d {H}h {M}m {S}s",
  "long": "{w} {label-ws}, {d} {label-ds}, {H} {label-hs}, {M} {label-ms}",
  "clock": "{HH}:{MM}:{SS}",
  "days-hrs": "{d}d {H}h",
  "weeks": "{w}w {d}d",
  "total-hr": "{total-h}h",
  "total-d": "{total-d}d"
};

function resolveFormat(format) {
  return presets[format] || format || presets["default"];
}

function formatTargetDate(date) {
  var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  return days[date.getDay()] + " " + date.getFullYear() + "-" +
    pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) + " " +
    pad2(date.getHours()) + ":" + pad2(date.getMinutes()) + ":" +
    pad2(date.getSeconds());
}

function countdownTooltip(ts, target, label) {
  var rows = [];
  if (label) rows.push("\uF015B " + label);
  if (ts.negative) {
    rows.push("⚠ Overdue");
    return drawTable("\uF00F0 Countdown", rows);
  }
  var parts = [];
  function add(n, icon, word) {
    if (n > 0) parts.push(icon + " " + n + " " + plural(word, n));
  }
  add(ts.weeks, "\uF0035", "week");
  add(ts.days, "\uF07DF", "day");
  add(ts.hours, "\uF0954", "hour");
  add(ts.minutes, "\uF02DA", "minute");
  add(ts.seconds, "\uF06EF", "second");
  if (parts.length === 0) parts.push("\uF0134 Done!");
  rows = rows.concat(parts);
  rows.push("");
  rows.push("\uF0150 " + formatTargetDate(target));
  return drawTable("\uF00F0 Countdown", rows);
}

function parseDuration(text) {
  var total = 0;
  var num = "";
  var i = 0;
  while (i < text.length) {
    var ch = text.charAt(i);
    if ((ch >= "0" && ch <= "9") || ch === ".") {
      num += ch;
      i++;
      continue;
    }
    if (num === "") return null;
    if (ch === "w") {
      total += parseFloat(num) * 604800;
      num = "";
    } else if (ch === "d") {
      total += parseFloat(num) * 86400;
      num = "";
    } else {
      var part = num + ch;
      var j = i + 1;
      while (j < text.length && text.charAt(j) >= "a" && text.charAt(j) <= "z") {
        part += text.charAt(j);
        j++;
      }
      var multiplier = 1;
      if (contains(part, "ms")) multiplier = 0.001;
      else if (contains(part, "s")) multiplier = 1;
      else if (contains(part, "m")) multiplier = 60;
      else if (contains(part, "h")) multiplier = 3600;
      else return null;
      total += parseFloat(num) * multiplier;
      num = "";
      i = j - 1;
    }
    i++;
  }
  return num === "" ? total : null;
}

var weekdays = {
  "sunday": 0, "sun": 0,
  "monday": 1, "mon": 1,
  "tuesday": 2, "tue": 2, "tues": 2,
  "wednesday": 3, "wed": 3,
  "thursday": 4, "thu": 4, "thur": 4,
  "friday": 5, "fri": 5,
  "saturday": 6, "sat": 6
};

function wallToFixedOffset(year, month, day, hour, minute, second, now) {
  // Go's time.Parse uses the current zone offset for a date with no explicit
  // offset, so a summer target keeps winter's offset. Date.UTC + the current
  // offset reproduces that instead of applying DST to the target.
  return Date.UTC(year, month - 1, day, hour, minute, second) -
    now.getTimezoneOffset() * 60000;
}

function nextWeekday(target, hour, minute, now) {
  var wall = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  var diff = (target - wall.getDay() + 7) % 7;
  var date = wallToFixedOffset(wall.getFullYear(), wall.getMonth() + 1,
    wall.getDate() + diff, hour, minute, 0, now);
  if (diff === 0 && date <= now.getTime()) date += 7 * 86400000;
  return new Date(date);
}

function parseTarget(text, now) {
  if (!text) return null;
  if (text.charAt(0) === "+") {
    var seconds = parseDuration(text.slice(1));
    return seconds === null ? null : new Date(now.getTime() + seconds * 1000);
  }

  var m = text.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?$/);
  if (m) {
    return new Date(wallToFixedOffset(parseInt(m[1]), parseInt(m[2]), parseInt(m[3]),
      parseInt(m[4] || "0"), parseInt(m[5] || "0"), parseInt(m[6] || "0"), now));
  }

  var parts = text.trim().split(/\s+/);
  var wd = weekdays[parts[0].toLowerCase()];
  if (wd !== undefined) {
    var hour = 0;
    var minute = 0;
    if (parts.length > 1) {
      var hm = parts[1].match(/^(\d{1,2}):(\d{2})$/);
      if (hm) {
        hour = parseInt(hm[1]);
        minute = parseInt(hm[2]);
      }
    }
    return nextWeekday(wd, hour, minute, now);
  }
  return null;
}

/* ------------------------------------------------------------------------- *
 * Calendar tooltip — a compact three-month view of the clock.jsonc calendar
 * ------------------------------------------------------------------------- */

var monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"];

function padLeft(str, width, ch) {
  while (str.length < width) str = ch + str;
  return str;
}

function monthGrid(year, month, today) {
  var first = new Date(year, month, 1);
  // Monday-first weekday index, matching the waybar calendar.
  var offset = (first.getDay() + 6) % 7;
  var days = new Date(year, month + 1, 0).getDate();

  var lines = [padLeft(monthNames[month], 20, " ")];
  lines.push(" Mo Tu We Th Fr Sa Su");
  var row = repeat("   ", offset);
  for (var day = 1; day <= days; day++) {
    var mark = (today && today.getFullYear() === year && today.getMonth() === month &&
      today.getDate() === day) ? "*" : " ";
    row += pad2(day) + mark;
    if ((offset + day) % 7 === 0) {
      lines.push(row);
      row = "";
    }
  }
  if (row !== "") lines.push(row);
  return lines;
}

function calendarText(date) {
  var blocks = [];
  for (var i = -1; i <= 1; i++) {
    var d = new Date(date.getFullYear(), date.getMonth() + i, 1);
    blocks.push(monthGrid(d.getFullYear(), d.getMonth(), date));
  }
  var height = 0;
  for (var b = 0; b < blocks.length; b++) height = Math.max(height, blocks[b].length);
  var out = "";
  for (var line = 0; line < height; line++) {
    var row = "";
    for (var k = 0; k < blocks.length; k++) {
      row += (k === 0 ? "" : "  ") + (blocks[k][line] || repeat(" ", 20));
    }
    out += (line === 0 ? "" : "\n") + row;
  }
  return out;
}
