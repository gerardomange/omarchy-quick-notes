// NotesFormatter.js - Smart formatting logic for Quick Notes plugin in Omarchy

function handleEnter(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;

  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  var lineSoFar = text.substring(lineStart, pos);
  var nextNewline = text.indexOf('\n', pos);
  var lineEnd = (nextNewline === -1) ? text.length : nextNewline;
  var restOfLine = text.substring(pos, lineEnd);

  // 1. Task / Checkbox item
  // Matches: "  - [ ] ", "  [ ] ", "  - [x] ", "  [x] ", "  • [ ] "
  var taskMatch = lineSoFar.match(/^(\s*)([-*•]?\s*\[[ xX]?\])\s*(.*)$/);
  if (taskMatch) {
    var indent = taskMatch[1];
    var box = taskMatch[2];
    var content = taskMatch[3];
    // If the item has no text and rest of line is empty, exit checklist mode
    if (content.trim() === "" && restOfLine.trim() === "") {
      textEdit.remove(lineStart, lineEnd);
      textEdit.cursorPosition = lineStart;
      return true;
    }
    // Next item starts unchecked
    var nextBox = box.replace(/\[[xX]\]/, "[ ]");
    var insertion = "\n" + indent + nextBox + " ";
    textEdit.insert(pos, insertion);
    textEdit.cursorPosition = pos + insertion.length;
    return true;
  }

  // 2. Numbered list: "  1. ", "  1) "
  var numMatch = lineSoFar.match(/^(\s*)(\d+)([.)])\s*(.*)$/);
  if (numMatch) {
    var indent = numMatch[1];
    var num = parseInt(numMatch[2], 10);
    var delim = numMatch[3];
    var content = numMatch[4];
    if (content.trim() === "" && restOfLine.trim() === "") {
      // Exit numbered list
      textEdit.remove(lineStart, lineEnd);
      textEdit.cursorPosition = lineStart;
      return true;
    }
    var nextNum = num + 1;
    var insertion = "\n" + indent + nextNum + delim + " ";
    textEdit.insert(pos, insertion);
    textEdit.cursorPosition = pos + insertion.length;
    return true;
  }

  // 3. Bullet list: "  - ", "  * ", "  • "
  var bulletMatch = lineSoFar.match(/^(\s*)([-*•])\s*(.*)$/);
  if (bulletMatch) {
    var indent = bulletMatch[1];
    var bullet = bulletMatch[2];
    var content = bulletMatch[3];
    if (content.trim() === "" && restOfLine.trim() === "") {
      // Exit bullet list
      textEdit.remove(lineStart, lineEnd);
      textEdit.cursorPosition = lineStart;
      return true;
    }
    var insertion = "\n" + indent + bullet + " ";
    textEdit.insert(pos, insertion);
    textEdit.cursorPosition = pos + insertion.length;
    return true;
  }

  // 4. Colon auto-indent (e.g. "Reminders:")
  if (lineSoFar.trim().endsWith(":")) {
    var indentMatch = lineSoFar.match(/^(\s*)/);
    var indent = indentMatch ? indentMatch[1] : "";
    var insertion = "\n" + indent + "  ";
    textEdit.insert(pos, insertion);
    textEdit.cursorPosition = pos + insertion.length;
    return true;
  }

  // 5. Preserve existing leading indentation
  var spaceMatch = lineSoFar.match(/^(\s+)/);
  if (spaceMatch) {
    var indent = spaceMatch[1];
    var insertion = "\n" + indent;
    textEdit.insert(pos, insertion);
    textEdit.cursorPosition = pos + insertion.length;
    return true;
  }

  return false;
}

function handleSpace(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  var lineSoFar = text.substring(lineStart, pos);

  // Auto-expand "[]" -> "[ ] "
  var boxMatch = lineSoFar.match(/^(\s*)\[\]$/);
  if (boxMatch) {
    var indent = boxMatch[1];
    textEdit.remove(lineStart, pos);
    textEdit.insert(lineStart, indent + "[ ] ");
    textEdit.cursorPosition = lineStart + indent.length + 4;
    return true;
  }

  // Auto-expand "-[]" or "- []" -> "- [ ] "
  var dashBoxMatch = lineSoFar.match(/^(\s*)- ?\[\]$/);
  if (dashBoxMatch) {
    var indent = dashBoxMatch[1];
    textEdit.remove(lineStart, pos);
    textEdit.insert(lineStart, indent + "- [ ] ");
    textEdit.cursorPosition = lineStart + indent.length + 6;
    return true;
  }

  // Auto-convert "* " -> "• "
  var starMatch = lineSoFar.match(/^(\s*)\*$/);
  if (starMatch) {
    var indent = starMatch[1];
    textEdit.remove(lineStart, pos);
    textEdit.insert(lineStart, indent + "• ");
    textEdit.cursorPosition = lineStart + indent.length + 2;
    return true;
  }

  return false;
}

function handleTab(textEdit, isShift) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  var nextNewline = text.indexOf('\n', pos);
  var lineEnd = (nextNewline === -1) ? text.length : nextNewline;
  var fullLine = text.substring(lineStart, lineEnd);

  if (isShift) {
    // Outdent: remove up to 2 leading spaces
    if (fullLine.indexOf("  ") === 0) {
      textEdit.remove(lineStart, lineStart + 2);
      textEdit.cursorPosition = Math.max(lineStart, pos - 2);
      return true;
    } else if (fullLine.indexOf(" ") === 0) {
      textEdit.remove(lineStart, lineStart + 1);
      textEdit.cursorPosition = Math.max(lineStart, pos - 1);
      return true;
    }
  } else {
    // Indent: add 2 leading spaces at start of line
    textEdit.insert(lineStart, "  ");
    textEdit.cursorPosition = pos + 2;
    return true;
  }
  return false;
}

function toggleTask(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  var nextNewline = text.indexOf('\n', pos);
  var lineEnd = (nextNewline === -1) ? text.length : nextNewline;
  var fullLine = text.substring(lineStart, lineEnd);

  // Toggle checked [x] to unchecked [ ]
  if (fullLine.match(/^(\s*[-*•]?\s*)\[[xX]\](.*)$/)) {
    var newLine = fullLine.replace(/^(\s*[-*•]?\s*)\[[xX]\]/, "$1[ ]");
    textEdit.remove(lineStart, lineEnd);
    textEdit.insert(lineStart, newLine);
    textEdit.cursorPosition = Math.min(pos, lineStart + newLine.length);
    return true;
  }

  // Toggle unchecked [ ] to checked [x]
  if (fullLine.match(/^(\s*[-*•]?\s*)\[\s*\](.*)$/)) {
    var newLine = fullLine.replace(/^(\s*[-*•]?\s*)\[\s*\]/, "$1[x]");
    textEdit.remove(lineStart, lineEnd);
    textEdit.insert(lineStart, newLine);
    textEdit.cursorPosition = Math.min(pos, lineStart + newLine.length);
    return true;
  }

  // If bullet line: convert to checkbox "- [ ] "
  if (fullLine.match(/^(\s*)([-*•])\s*(.*)$/)) {
    var newLine = fullLine.replace(/^(\s*)([-*•])\s*/, "$1- [ ] ");
    textEdit.remove(lineStart, lineEnd);
    textEdit.insert(lineStart, newLine);
    textEdit.cursorPosition = lineStart + newLine.length;
    return true;
  }

  // If regular text: prepend "[ ] "
  var indentMatch = fullLine.match(/^(\s*)(.*)$/);
  var indent = indentMatch ? indentMatch[1] : "";
  var content = indentMatch ? indentMatch[2] : fullLine;
  var newLine = indent + "[ ] " + content;
  textEdit.remove(lineStart, lineEnd);
  textEdit.insert(lineStart, newLine);
  textEdit.cursorPosition = pos + 4;
  return true;
}

function insertBullet(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  textEdit.insert(lineStart, "• ");
  textEdit.cursorPosition = pos + 2;
}

function insertNumber(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;

  var prevNum = 0;
  if (lineStart > 1) {
    var prevLineStart = text.lastIndexOf('\n', lineStart - 2);
    prevLineStart = (prevLineStart === -1) ? 0 : prevLineStart + 1;
    var prevLine = text.substring(prevLineStart, lineStart - 1);
    var m = prevLine.match(/^\s*(\d+)[.)]/);
    if (m) prevNum = parseInt(m[1], 10);
  }

  var numStr = (prevNum > 0 ? (prevNum + 1) : 1) + ". ";
  textEdit.insert(lineStart, numStr);
  textEdit.cursorPosition = pos + numStr.length;
}

function insertTask(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var lastNewline = text.lastIndexOf('\n', pos - 1);
  var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
  textEdit.insert(lineStart, "[ ] ");
  textEdit.cursorPosition = pos + 4;
}

function parseReminder(textEdit) {
  var pos = textEdit.cursorPosition;
  var text = textEdit.text;
  var target = "";

  if (textEdit.selectedText && textEdit.selectedText.trim().length > 0) {
    target = textEdit.selectedText.trim();
  } else {
    var lastNewline = text.lastIndexOf('\n', pos - 1);
    var lineStart = (lastNewline === -1) ? 0 : lastNewline + 1;
    var nextNewline = text.indexOf('\n', pos);
    var lineEnd = (nextNewline === -1) ? text.length : nextNewline;
    target = text.substring(lineStart, lineEnd).trim();
  }

  if (!target) return null;

  target = target.replace(/^([-*•]|\d+[.)]|\[[ xX]?\]|- \[[ xX]?\])\s*/, "").trim();

  // "15m Call dentist" or "15 Call dentist"
  var m = target.match(/^(\d+)\s*(?:m|min|mins|minutes)?\s+(.*)$/i);
  if (m && parseInt(m[1], 10) > 0 && m[2].trim()) {
    return { minutes: parseInt(m[1], 10), message: m[2].trim() };
  }

  // "remind me in 10 mins to buy milk"
  m = target.match(/(?:remind(?:\s+me)?\s+(?:in\s+)?|in\s+)?(\d+)\s*(?:m|min|mins|minutes)\s+(?:to\s+)?(.*)$/i);
  if (m && parseInt(m[1], 10) > 0 && m[2].trim()) {
    return { minutes: parseInt(m[1], 10), message: m[2].trim() };
  }

  // "Buy milk in 15m"
  m = target.match(/^(.*?)\s+in\s+(\d+)\s*(?:m|min|mins|minutes)$/i);
  if (m && parseInt(m[2], 10) > 0 && m[1].trim()) {
    return { minutes: parseInt(m[2], 10), message: m[1].trim() };
  }

  return null;
}

function getStats(text) {
  if (!text || text.length === 0) {
    return { lines: 0, words: 0, chars: 0, tasks: 0, doneTasks: 0 };
  }
  var lines = text.split('\n').length;
  var words = text.trim().split(/\s+/).filter(function(w) { return w.length > 0; }).length;
  var chars = text.length;
  var tasks = (text.match(/\[[ xX]\]/g) || []).length;
  var doneTasks = (text.match(/\[[xX]\]/g) || []).length;
  return {
    lines: lines,
    words: words,
    chars: chars,
    tasks: tasks,
    doneTasks: doneTasks
  };
}
