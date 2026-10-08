(function () {
  var w = window, d = document;
  if (w.turnstileRuby) { w.turnstileRuby.render(); return; }

  var whenReady = function (fn) {
    if (w.turnstile) { fn(); } else { setTimeout(function () { whenReady(fn); }, 50); }
  };

  // api.js only scans the page once, widgets added by a Turbo render have to be rendered here.
  var render = function () {
    if (!w.turnstile || d.readyState === "loading" || d.documentElement.hasAttribute("data-turbo-preview")) return;
    d.querySelectorAll(".cf-turnstile").forEach(function (el) {
      if (!el.childElementCount) w.turnstile.render(el);
    });
  };

  // Pages that are cached or replaced must not keep a dead widget or a spent token.
  var cleanup = function () {
    d.querySelectorAll(".cf-turnstile, [data-turnstile-invisible]").forEach(function (el) {
      if (!el.childElementCount) return;
      try { w.turnstile.remove(el); } catch (e) {}
      el.innerHTML = "";
    });
  };

  var verified = function (el, form, token) {
    var name = el.getAttribute("data-callback");
    if (name && typeof w[name] === "function") { w[name](token); return; }
    el.turnstileVerified = true;
    var submitter = el.turnstileSubmitter;
    if (form.requestSubmit) {
      form.requestSubmit(submitter && submitter.form === form ? submitter : undefined);
    } else {
      form.submit();
    }
  };

  // Invisible widgets: hold the submit back, run the challenge, then submit with a fresh token.
  var onSubmit = function (event) {
    var form = event.target;
    var el = form.querySelector && form.querySelector("[data-turnstile-invisible][data-sitekey]");
    if (!el) return;
    if (el.turnstileVerified) { el.turnstileVerified = false; return; }
    event.preventDefault();
    event.stopPropagation();
    el.turnstileSubmitter = event.submitter;
    whenReady(function () {
      if (el.childElementCount) { w.turnstile.reset(el); return; }
      w.turnstile.render(el, { callback: function (token) { verified(el, form, token); } });
    });
  };

  d.addEventListener("turbo:render", render);
  d.addEventListener("turbo:frame-render", render);
  d.addEventListener("turbo:before-cache", cleanup);
  d.addEventListener("turbo:before-render", cleanup);
  d.addEventListener("submit", onSubmit, true);
  w.turnstileRuby = { render: render };
  render();
})();
