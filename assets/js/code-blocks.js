/**
 * Enhance fenced/indented code blocks: line numbers, wrap toggle, copy (#71).
 * Wrap is the default so long lines stay in the measure; line numbers track
 * the wrapped source line (#222). GitHub-inspired toolbar; progressive only.
 */
(function () {
  "use strict";

  var VOID = {
    area: 1, base: 1, br: 1, col: 1, embed: 1, hr: 1, img: 1, input: 1,
    link: 1, meta: 1, param: 1, source: 1, track: 1, wbr: 1
  };

  function getCodeText(pre) {
    var stored = pre.getAttribute("data-code-text");
    if (stored != null) return stored;
    var lines = pre.querySelectorAll(".code-block__line");
    if (lines.length) {
      var parts = new Array(lines.length);
      for (var i = 0; i < lines.length; i++) parts[i] = lines[i].textContent;
      return parts.join("\n");
    }
    var code = pre.querySelector("code");
    return code ? code.textContent : pre.textContent;
  }

  function closeOpenTags(stack) {
    var out = "";
    for (var i = stack.length - 1; i >= 0; i--) {
      var name = stack[i].match(/^<([a-zA-Z0-9:-]+)/);
      if (name) out += "</" + name[1] + ">";
    }
    return out;
  }

  function openTagsHtml(stack) {
    return stack.join("");
  }

  function applyTagToStack(tag, stack) {
    var m = tag.match(/^<\/?([a-zA-Z0-9:-]+)/);
    var name = m ? m[1].toLowerCase() : "";
    if (!name || tag.charAt(1) === "!" || tag.charAt(1) === "?") return;
    var isClose = tag.charAt(1) === "/";
    var selfClosing = /\/\s*>$/.test(tag) || VOID[name];
    if (isClose) {
      if (stack.length) stack.pop();
      return;
    }
    if (!selfClosing) stack.push(tag);
  }

  function splitHighlightedLines(html) {
    html = String(html || "").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
    if (html.charAt(html.length - 1) === "\n") html = html.slice(0, -1);
    if (!html) return [""];

    var lines = [];
    var buf = "";
    var stack = [];
    var i = 0;

    while (i < html.length) {
      var ch = html.charAt(i);
      if (ch === "<") {
        var end = html.indexOf(">", i);
        if (end === -1) {
          buf += html.slice(i);
          break;
        }
        var tag = html.slice(i, end + 1);
        buf += tag;
        applyTagToStack(tag, stack);
        i = end + 1;
      } else if (ch === "\n") {
        lines.push(buf + closeOpenTags(stack));
        buf = openTagsHtml(stack);
        i += 1;
      } else {
        buf += ch;
        i += 1;
      }
    }
    lines.push(buf + closeOpenTags(stack));
    return lines;
  }

  function wrapSourceLines(pre) {
    var code = pre.querySelector("code") || pre;
    if (code.querySelector(".code-block__line")) return;
    var html = code.innerHTML;
    if (html == null) return;
    var parts = splitHighlightedLines(html);
    var out = "";
    for (var i = 0; i < parts.length; i++) {
      out += '<span class="code-block__line" data-n="' + (i + 1) + '">' +
        parts[i] + "</span>";
    }
    code.innerHTML = out;
  }

  function enhance(pre) {
    if (pre.closest(".code-block")) return;
    // Never chrome real media embeds (embeds must win over code view — #156)
    if (pre.closest(".embed, [data-embed]")) return;
    var text = getCodeText(pre);
    if (text == null) return;

    pre.setAttribute("data-code-text", text);

    var wrap = document.createElement("div");
    wrap.className = "code-block";

    var toolbar = document.createElement("div");
    toolbar.className = "code-block__toolbar";
    toolbar.setAttribute("role", "toolbar");
    toolbar.setAttribute("aria-label", "Code block");

    var wrapBtn = document.createElement("button");
    wrapBtn.type = "button";
    wrapBtn.className = "code-block__btn";
    wrapBtn.setAttribute("data-action", "wrap");
    wrapBtn.setAttribute("aria-pressed", "true");
    wrapBtn.textContent = "Unwrap";

    var copyBtn = document.createElement("button");
    copyBtn.type = "button";
    copyBtn.className = "code-block__btn";
    copyBtn.setAttribute("data-action", "copy");
    copyBtn.textContent = "Copy";

    toolbar.appendChild(wrapBtn);
    toolbar.appendChild(copyBtn);

    var body = document.createElement("div");
    body.className = "code-block__body";

    wrapSourceLines(pre);

    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(toolbar);
    wrap.appendChild(body);
    body.appendChild(pre);

    wrapBtn.addEventListener("click", function () {
      var off = wrap.classList.toggle("is-nowrap");
      wrapBtn.setAttribute("aria-pressed", off ? "false" : "true");
      wrapBtn.textContent = off ? "Wrap" : "Unwrap";
    });

    copyBtn.addEventListener("click", function () {
      var payload = getCodeText(pre) || "";
      function done(ok) {
        var prev = copyBtn.textContent;
        copyBtn.textContent = ok ? "Copied!" : "Failed";
        copyBtn.disabled = true;
        setTimeout(function () {
          copyBtn.textContent = prev;
          copyBtn.disabled = false;
        }, 1600);
      }
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(payload).then(
          function () { done(true); },
          function () { fallbackCopy(payload, done); }
        );
      } else {
        fallbackCopy(payload, done);
      }
    });
  }

  function fallbackCopy(text, done) {
    try {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      var ok = document.execCommand("copy");
      document.body.removeChild(ta);
      done(ok);
    } catch (e) {
      done(false);
    }
  }

  function init() {
    var nodes = document.querySelectorAll("main pre");
    for (var i = 0; i < nodes.length; i++) {
      enhance(nodes[i]);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
