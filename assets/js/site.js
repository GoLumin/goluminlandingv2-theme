(function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* Everything measured goes through here, so a missing tag manager is a
     no-op rather than a thrown error that stops the script. */
  function push(data) { window.dataLayer = window.dataLayer || []; window.dataLayer.push(data); }

  /* Nav: shadow on scroll */
  var nav = document.querySelector('[data-nav]');
  function onScroll() {
    if (!nav) return;
    nav.classList.toggle('is-scrolled', window.scrollY > 8);
  }
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  /* Nav: dropdown panels (hover on desktop, click/keyboard everywhere) */
  var items = document.querySelectorAll('[data-dropdown]');
  function closeAll(except) {
    items.forEach(function (it) {
      if (it !== except) {
        it.classList.remove('is-open');
        var b = it.querySelector('button');
        if (b) b.setAttribute('aria-expanded', 'false');
      }
    });
  }
  items.forEach(function (it) {
    var btn = it.querySelector('button');
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = it.classList.toggle('is-open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      closeAll(it);
    });
    it.addEventListener('mouseenter', function () {
      if (window.matchMedia('(hover: hover)').matches) {
        it.classList.add('is-open');
        btn.setAttribute('aria-expanded', 'true');
      }
    });
    it.addEventListener('mouseleave', function () {
      if (window.matchMedia('(hover: hover)').matches) {
        it.classList.remove('is-open');
        btn.setAttribute('aria-expanded', 'false');
      }
    });
  });
  document.addEventListener('click', function () { closeAll(null); });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { closeAll(null); closeDrawer(); }
  });

  /* Nav: mobile drawer */
  var toggle = document.querySelector('[data-nav-toggle]');
  var drawer = document.querySelector('[data-nav-drawer]');
  function closeDrawer() {
    if (!drawer) return;
    document.body.classList.remove('drawer-open');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-label', 'Open menu');
  }
  if (toggle && drawer) {
    toggle.addEventListener('click', function () {
      var open = document.body.classList.toggle('drawer-open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    });
    drawer.querySelectorAll('a').forEach(function (a) { a.addEventListener('click', closeDrawer); });
  }

  /* Hero entrance: once the sequence has had time to play, pin everything visible */
  setTimeout(function () {
    document.querySelectorAll('.hero [data-enter]').forEach(function (el) { el.classList.add('is-done'); });
  }, 1700);

  /* Marquee: duplicate the track once so the loop is seamless */
  document.querySelectorAll('[data-marquee]').forEach(function (t) { t.innerHTML += t.innerHTML; });

  /* Reveal on scroll */
  var revealEls = document.querySelectorAll('[data-reveal]');
  if (reduce || !('IntersectionObserver' in window)) {
    revealEls.forEach(function (el) { el.classList.add('is-in'); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          en.target.classList.add('is-in');
          io.unobserve(en.target);
        }
      });
    }, { rootMargin: '0px 0px -6% 0px', threshold: 0 });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* Bars grow when seen */
  var bars = document.querySelectorAll('[data-bar]');
  if (bars.length) {
    var grow = function (el) { el.style.width = el.getAttribute('data-bar') + '%'; };
    if (reduce || !('IntersectionObserver' in window)) {
      bars.forEach(grow);
    } else {
      var bo = new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) { grow(en.target); bo.unobserve(en.target); }
        });
      }, { threshold: 0.4 });
      bars.forEach(function (b) { bo.observe(b); });
    }
  }

  /* Forms: real submit to the CMS form endpoint (same-origin via the
     worker's /api proxy). On success the visitor goes to /thank-you,
     carrying the lead id, which is where the conversion fires: that is
     how this site measured leads before the static rebuild, and the
     Google Ads conversion and the GTM triggers are still built around
     it. On any failure: an honest fallback with phone + email, never a
     fake success over a lost lead. */
  document.querySelectorAll('[data-form]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var ok = true;
      form.querySelectorAll('[required]').forEach(function (f) {
        var bad = !f.value || (f.type === 'email' && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(f.value));
        f.closest('.field').classList.toggle('is-invalid', bad);
        if (bad) ok = false;
      });
      if (!ok) {
        var first = form.querySelector('.is-invalid input, .is-invalid select');
        if (first) first.focus();
        return;
      }
      var btn = form.querySelector('button[type="submit"]');
      if (btn) { btn.disabled = true; btn.dataset.label = btn.textContent; btn.textContent = 'Sending…'; }
      var finish = function (sent) {
        form.classList.add('is-done');
        var done = form.querySelector('.form-done');
        if (done) {
          if (!sent) {
            done.innerHTML = '<strong>That didn\u2019t go through.</strong><p>Our form is briefly offline. Call <a href="tel:+14152836736">(415) 283-6736</a> or email <a href="mailto:marketing@golumin.io">marketing@golumin.io</a> \u2014 a partner answers both.</p>';
          }
          done.hidden = false; done.setAttribute('tabindex', '-1'); done.focus();
        }
      };
      var slug = (form.action.match(/\/api\/forms\/([^/]+)\/submissions/) || [])[1] || 'audit';
      push({ event: 'form_submit' });
      push({ event: 'submit_' + slug, audit_type: (form.querySelector('[name="audit_type"]') || {}).value });
      fetch(form.action, { method: 'POST', body: new FormData(form), headers: { 'Accept': 'application/json' } })
        .then(function (res) {
          if (!res.ok) { finish(false); return; }
          return res.json().catch(function () { return {}; }).then(function (body) {
            var next = new URLSearchParams({ form: slug, back: location.pathname });
            if (body && body.id) next.set('lead', String(body.id));
            location.href = '/thank-you?' + next;
          });
        })
        .catch(function () { finish(false); })
        .finally(function () { if (btn) { btn.disabled = false; btn.textContent = btn.dataset.label; } });
    });
    form.querySelectorAll('input, select, textarea').forEach(function (f) {
      f.addEventListener('input', function () { f.closest('.field').classList.remove('is-invalid'); });
    });
  });

  /* The thank-you page: one lead_submitted per accepted lead (?lead=<id>),
     with the Google Ads and OpenAI conversions, never twice for the same
     lead. Ported from the theme this site replaced. */
  if (/^\/thank-you\/?$/.test(location.pathname)) {
    try {
      var params = new URLSearchParams(location.search);
      var back = params.get('back');
      if (back && /^\/[A-Za-z0-9\-._~/]*$/.test(back) && back.slice(0, 2) !== '//') {
        document.querySelectorAll('[data-back]').forEach(function (a) { a.href = back; });
      }
      var leadId = params.get('lead');
      if (leadId) {
        history.replaceState(null, '', location.pathname);
        var seen = [];
        try { seen = JSON.parse(localStorage.getItem('lumin_leads') || '[]'); } catch (e) {}
        if (seen.indexOf(leadId) === -1) {
          push({ event: 'lead_submitted', lead_id: leadId, form_location: params.get('form') || 'unknown' });
          try { if (window.gtag) window.gtag('event', 'conversion', { send_to: 'AW-18424158289/mTzKCPb8uvUcENGwqdFE', transaction_id: leadId }); } catch (e) {}
          try { if (window.oaiq) window.oaiq('measure', 'subscription_created', { type: 'plan_enrollment' }); } catch (e) {}
          try { localStorage.setItem('lumin_leads', JSON.stringify(seen.concat(leadId).slice(-20))); } catch (e) {}
        }
      }
    } catch (e) {}
  }

  /* The 404: which dead addresses people reach, and what sent them. */
  if (/^\/404\/?$/.test(location.pathname) || document.querySelector('[data-not-found]')) {
    push({ event: 'page_not_found', missing_path: location.pathname + location.search, missing_referrer: document.referrer || '(none)' });
  }

  /* Form proof line: one real result at a time */
  document.querySelectorAll('[data-proof]').forEach(function (box) {
    var items = box.querySelectorAll('span'); if (!items.length) return;
    var i = 0; items.forEach(function (s) { s.classList.remove('is-on'); }); items[0].classList.add('is-on');
    if (reduce || items.length < 2) return;
    setInterval(function () {
      items[i].classList.remove('is-on'); i = (i + 1) % items.length; items[i].classList.add('is-on');
    }, 6000);
  });

  /* Mobile bar: hide while the form is on screen */
  var bar = document.querySelector('[data-mobile-bar]');
  var forms = document.querySelectorAll('.form-card');
  if (bar && forms.length && 'IntersectionObserver' in window) {
    var visible = new Set();
    var fo = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { en.isIntersecting ? visible.add(en.target) : visible.delete(en.target); });
      bar.classList.toggle('is-hidden', visible.size > 0);
    }, { threshold: 0.15 });
    forms.forEach(function (f) { fo.observe(f); });
  }
})();

/* Attribution: fill the hidden fields the form backend records.
   First-touch landing path and referrer persist for the session; click IDs
   and UTMs come from the URL that brought the visitor in. */
(function () {
  var qs = new URLSearchParams(location.search);
  var KEYS = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'gclid', 'fbclid', 'msclkid'];
  var store = {};
  try {
    store = JSON.parse(sessionStorage.getItem('gl_attr') || '{}');
    if (!store.landing_path) {
      store.landing_path = location.pathname;
      store.referrer = document.referrer || '';
      KEYS.forEach(function (k) { if (qs.get(k)) store[k] = qs.get(k); });
      sessionStorage.setItem('gl_attr', JSON.stringify(store));
    } else {
      KEYS.forEach(function (k) { if (qs.get(k) && !store[k]) store[k] = qs.get(k); });
      sessionStorage.setItem('gl_attr', JSON.stringify(store));
    }
  } catch (e) { /* storage blocked: fall through with current-page values */ }
  document.querySelectorAll('form[data-form]').forEach(function (form) {
    var set = function (name, value) {
      var f = form.querySelector('input[name="' + name + '"]');
      if (f && !f.value) f.value = value || '';
    };
    KEYS.forEach(function (k) { set(k, store[k] || qs.get(k)); });
    set('landing_path', store.landing_path || location.pathname);
    set('referrer', store.referrer || document.referrer);
    set('form_path', location.pathname);
  });
})();
