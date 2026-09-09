// Put a playable replay in a book page.
//
//   <div class="tb-replay" data-src="tutorials/2-fight.json" data-turn="3" data-height="320"></div>
//
// The viewer is the cartridge's own bundle, vendored into src/viz/ -- so a lesson shows what the
// engine does, re-simulated in the browser from the same component digest that recorded it. A
// diagram of a rule can be wrong about the rule; this cannot.
//
// mdBook loads `additional-js` as a classic script, so the module is pulled in with a dynamic
// import. It is loaded once and only if a page actually has a replay on it: the component is a
// quarter of a megabyte and most pages do not want it.
(function () {
  "use strict";

  function root() {
    // mdBook defines this on every page; the fallback is for a page opened on its own.
    return typeof path_to_root === "string" ? path_to_root : "";
  }

  function fallback(el, message) {
    el.innerHTML =
      '<p style="margin:0;padding:12px;border:1px solid currentColor;border-radius:6px;opacity:.7">' +
      message +
      "</p>";
  }

  function boot() {
    var slots = Array.prototype.slice.call(document.querySelectorAll(".tb-replay"));
    if (!slots.length) return;

    import(root() + "viz/viz.js")
      .then(function (viz) {
        slots.forEach(function (el) {
          var src = el.dataset.src;
          if (!src) return fallback(el, "This replay has no data-src.");
          var opts = {};
          ["turn", "from", "to", "zoom", "speed"].forEach(function (k) {
            if (el.dataset[k] != null) opts[k] = Number(el.dataset[k]);
          });
          if (el.dataset.centre) opts.centre = el.dataset.centre.split(",").map(Number);
          if (el.dataset.autoplay === "true") opts.autoplay = true;
          if (el.dataset.height) el.style.height = el.dataset.height + "px";
          else el.style.height = "360px";

          viz.mount(el, root() + src, opts).catch(function (e) {
            fallback(el, "This replay could not be loaded: " + e.message);
          });
        });
      })
      .catch(function (e) {
        slots.forEach(function (el) {
          // The prose above every slot says what the replay shows, so a page without the viewer is
          // still a page that teaches the rule. That is why the fallback is a sentence and not a
          // broken frame.
          fallback(el, "The replay viewer could not be loaded (" + e.message + ").");
        });
      });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
