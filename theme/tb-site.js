// The bar's theme switch -- one button, sun or moon, wired to mdBook's own theme machinery.
//
// mdBook's five-theme paintbrush popup is hidden (tinybrains.css §4) rather than removed, because
// book.js holds references to it and is where all the real work happens: swapping the html class,
// enabling the right syntax stylesheet, storing the choice. So this button does not set a theme. It
// clicks the button in that popup, and book.js does exactly what it does for its own control.
//
// WHICH GLYPH SHOWS IS CSS, not this file -- both are in the markup and the theme class picks one,
// so the button is right on the first paint. What is left here is the click and the label, and the
// label is the part a screen reader has instead of the glyph.
//
// The switch used to carry the choice back to the application through a shared `tb.theme` key, which
// worked while the book was mounted at /docs/ on the site's origin. The book has its own host now,
// so the two localStorages are different localStorages and there is nothing to hand over.
(function () {
  "use strict";

  var SAYS = {
    navy: "Switch to the light theme", // shown while the book is dark
    light: "Switch to the dark theme",
  };

  function boot() {
    var button = document.getElementById("tb-theme-switch");
    if (!button) return;

    // What is on is read from the html element rather than remembered here: book.js is what writes
    // the class, and it also writes it on load before this script runs.
    function current() {
      return document.documentElement.classList.contains("light") ? "light" : "navy";
    }

    function label() {
      var says = SAYS[current()];
      button.setAttribute("aria-label", says);
      button.setAttribute("title", says);
    }

    button.addEventListener("click", function () {
      var next = current() === "light" ? "navy" : "light";
      var target = document.getElementById("mdbook-theme-" + next);
      if (target) target.click();
    });

    label();
    // book.js swaps the class on <html>, so that is what the label follows -- the same attribute
    // watch theme/tb-replay.js uses to re-dress the viewer.
    new MutationObserver(label).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
