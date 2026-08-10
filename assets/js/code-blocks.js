/**
 * Enhance fenced/indented code blocks: line numbers, wrap toggle, copy (#71).
 * GitHub-inspired toolbar; progressive enhancement only.
 */
(function () {
  "use strict";

  function lineCount(text) {
    if (!text) return 1;
    // Trailing newline should not invent an extra blank line number
    var normalized = text.replace(/\n$/, "");
    if (!normalized) return 1;
    return normalized.split("\n").length;
  }

  function buildLineNumbers(n) {
    var parts = new Array(n);
    for (var i = 0; i < n; i++) parts[i] = String(i + 1);
    return parts.join("\n");
  }

  function getCodeText(pre) {
    var code = pre.querySelector("code");
    return code ? code.textContent : pre.textContent;
  }

  function enhance(pre) {
    if (pre.closest(".code-block")) return;
    // Never chrome real media embeds (embeds must win over code view — #156)
    if (pre.closest(".embed, [data-embed]")) return;
    // Skip empty blocks
    var text = getCodeText(pre);
    if (text == null) return;

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
    wrapBtn.setAttribute("aria-pressed", "false");
    wrapBtn.textContent = "Wrap";

    var copyBtn = document.createElement("button");
    copyBtn.type = "button";
    copyBtn.className = "code-block__btn";
    copyBtn.setAttribute("data-action", "copy");
    copyBtn.textContent = "Copy";

    toolbar.appendChild(wrapBtn);
    toolbar.appendChild(copyBtn);

    var body = document.createElement("div");
    body.className = "code-block__body";

    var lines = document.createElement("div");
    lines.className = "code-block__lines";
    lines.setAttribute("aria-hidden", "true");
    lines.textContent = buildLineNumbers(lineCount(text));

    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(toolbar);
    wrap.appendChild(body);
    body.appendChild(lines);
    body.appendChild(pre);

    wrapBtn.addEventListener("click", function () {
      var on = wrap.classList.toggle("is-wrap");
      wrapBtn.setAttribute("aria-pressed", on ? "true" : "false");
      wrapBtn.textContent = on ? "Unwrap" : "Wrap";
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
