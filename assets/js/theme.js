/**
 * Light/dark theme toggle with localStorage persistence (#87).
 * Early boot script in head.html sets data-theme before paint.
 */
(function () {
  "use strict";

  var STORAGE_KEY = "theme";

  function systemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  function resolvedTheme() {
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      if (stored === "light" || stored === "dark") return stored;
    } catch (e) { /* private mode */ }
    return systemTheme();
  }

  function apply(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    var btn = document.querySelector(".theme-toggle");
    if (!btn) return;
    var next = theme === "dark" ? "light" : "dark";
    btn.setAttribute(
      "aria-label",
      next === "dark" ? "Switch to dark mode" : "Switch to light mode"
    );
    btn.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
  }

  function toggle() {
    var next = resolvedTheme() === "dark" ? "light" : "dark";
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch (e) { /* ignore */ }
    apply(next);
  }

  function init() {
    apply(resolvedTheme());
    var btn = document.querySelector(".theme-toggle");
    if (btn) btn.addEventListener("click", toggle);

    // Follow system only when user has not chosen
    try {
      var mq = window.matchMedia("(prefers-color-scheme: dark)");
      var onChange = function () {
        var stored = null;
        try {
          stored = localStorage.getItem(STORAGE_KEY);
        } catch (e) { /* ignore */ }
        if (stored !== "light" && stored !== "dark") {
          apply(systemTheme());
        }
      };
      if (mq.addEventListener) mq.addEventListener("change", onChange);
      else if (mq.addListener) mq.addListener(onChange);
    } catch (e) { /* ignore */ }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
