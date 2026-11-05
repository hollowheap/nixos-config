use anyhow::{Context, Result};
use headless_chrome::browser::tab::Tab;
use headless_chrome::protocol::cdp::Emulation;
use headless_chrome::{Browser, LaunchOptions};
use regex::Regex;
use serde_json::{json, Value};
use std::collections::HashSet;
use std::ffi::OsStr;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

const JS: &str = r##"
(() => {
  const esc = (s) => (window.CSS && CSS.escape ? CSS.escape(s) : s.replace(/[^a-zA-Z0-9_-]/g, "\\$&"));
  const selector = (el) => {
    const parts = [];
    let n = el;
    while (n && n.nodeType === 1 && parts.length < 6) {
      if (n.id) { parts.unshift(n.tagName.toLowerCase() + "#" + esc(n.id)); break; }
      let p = n.tagName.toLowerCase();
      const parent = n.parentElement;
      if (parent) {
        const sibs = Array.from(parent.children).filter((c) => c.tagName === n.tagName);
        if (sibs.length > 1) p += ":nth-of-type(" + (sibs.indexOf(n) + 1) + ")";
      }
      parts.unshift(p);
      n = n.parentElement;
    }
    return parts.join(" > ");
  };
  const rgba = (css) => {
    const m = /^rgba?\(([^)]+)\)$/.exec((css || "").trim());
    if (!m) return null;
    const p = m[1].split(/[ ,\/]+/).filter(Boolean).map(Number);
    if (p.length < 3 || p.slice(0, 3).some((v) => Number.isNaN(v))) return null;
    return { r: p[0], g: p[1], b: p[2], a: p.length > 3 && !Number.isNaN(p[3]) ? p[3] : 1 };
  };
  const compositedBg = (el) => {
    const layers = [];
    let n = el;
    while (n && n.nodeType === 1) {
      const cs = getComputedStyle(n);
      if (cs.backgroundImage && cs.backgroundImage !== "none") return { unknown: "background-image" };
      const c = rgba(cs.backgroundColor);
      if (c && c.a > 0) { layers.push(c); if (c.a >= 1) break; }
      n = n.parentElement;
    }
    let out = { r: 255, g: 255, b: 255 };
    for (let i = layers.length - 1; i >= 0; i--) {
      const c = layers[i];
      out = {
        r: c.r * c.a + out.r * (1 - c.a),
        g: c.g * c.a + out.g * (1 - c.a),
        b: c.b * c.a + out.b * (1 - c.a)
      };
    }
    return out;
  };
  const visible = (el) => {
    for (let n = el; n && n.nodeType === 1; n = n.parentElement) {
      const cs = getComputedStyle(n);
      if (cs.display === "none" || cs.visibility === "hidden") return false;
      if (cs.contentVisibility === "hidden") return false;
      if (parseFloat(cs.opacity) === 0) return false;
      if (n.tagName === "DETAILS" && !n.open) {
        const summary = n.querySelector(":scope > summary");
        if (el !== summary && !(summary && summary.contains(el))) return false;
      }
    }
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  };
  const accessibleName = (el) => {
    const aria = el.getAttribute("aria-label");
    if (aria && aria.trim()) return aria.trim();
    const by = el.getAttribute("aria-labelledby");
    if (by) {
      const t = by.split(/\s+/).map((id) => {
        const e = document.getElementById(id);
        return e ? (e.innerText || e.textContent || "") : "";
      }).join(" ").trim();
      if (t) return t;
    }
    const alt = el.getAttribute("alt");
    if (alt && alt.trim()) return alt.trim();
    const title = el.getAttribute("title");
    if (title && title.trim()) return title.trim();
    return (el.innerText || el.value || el.textContent || "").trim().slice(0, 120);
  };
  const interactiveSel = "a[href],button,input,select,textarea,summary,[role=button],[role=link],[role=tab],[role=menuitem],[role=switch],[role=checkbox],[role=radio],[tabindex]";
  const elements = Array.from(document.querySelectorAll("body *")).filter(visible).map((el) => {
    const cs = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    const hasText = Array.from(el.childNodes).some((n) => n.nodeType === 3 && (n.textContent || "").trim().length > 0);
    const tag = el.tagName.toLowerCase();
    return {
      selector: selector(el),
      tag,
      role: el.getAttribute("role"),
      name: accessibleName(el),
      hasText,
      disabled: el.disabled === true || el.getAttribute("aria-disabled") === "true",
      text: (el.innerText || "").trim().slice(0, 160),
      color: cs.color,
      background: compositedBg(el),
      fontSize: parseFloat(cs.fontSize) || 0,
      fontWeight: parseInt(cs.fontWeight, 10) || 400,
      rect: { x: r.x + window.scrollX, y: r.y + window.scrollY, w: r.width, h: r.height },
      overflowX: el.scrollWidth - el.clientWidth,
      overflowY: el.scrollHeight - el.clientHeight,
      overflow: cs.overflowX + "/" + cs.overflowY,
      whiteSpace: cs.whiteSpace,
      textOverflow: cs.textOverflow,
      tabindex: el.getAttribute("tabindex"),
      interactive: el.matches(interactiveSel),
      expanded: el.getAttribute("aria-expanded"),
      hasPopup: el.getAttribute("aria-haspopup"),
      href: tag === "a" ? el.href : null
    };
  });
  const focusableSel = "a[href],button,input,select,textarea,summary,[tabindex]";
  const hiddenAncestor = (el) => {
    for (let n = el; n && n.nodeType === 1; n = n.parentElement) {
      if (n.getAttribute("aria-hidden") === "true") return "aria-hidden";
      if (n.hasAttribute("inert")) return "inert";
    }
    return null;
  };
  const focusableElements = Array.from(document.querySelectorAll(focusableSel))
    .filter((el) => !el.disabled && el.tabIndex >= 0 && visible(el));
  const orderedFocusables = [
    ...focusableElements.filter((el) => el.tabIndex > 0).sort((a, b) => a.tabIndex - b.tabIndex),
    ...focusableElements.filter((el) => el.tabIndex === 0)
  ];
  const focusables = orderedFocusables.map((el, index) => ({
    order: index + 1,
    selector: selector(el),
    name: accessibleName(el),
    tabIndex: el.tabIndex,
    hiddenBy: hiddenAncestor(el)
  }));
  const candidates = elements.filter((e) => e.interactive && !e.disabled).map((e) => {
    let kind = "action";
    if (e.expanded !== null || e.hasPopup !== null || e.tag === "summary") kind = "disclosure";
    else if (e.tag === "a" && e.href) kind = "navigation";
    return { selector: e.selector, name: e.name, tag: e.tag, kind };
  });
  return JSON.stringify({
    title: document.title,
    url: location.href,
    lang: document.documentElement.lang || null,
    viewport: {
      width: window.innerWidth,
      height: window.innerHeight,
      documentWidth: document.documentElement.scrollWidth
    },
    scheme: window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light",
    reducedMotion: window.matchMedia("(prefers-reduced-motion: reduce)").matches,
    headings: Array.from(document.querySelectorAll("h1,h2,h3,h4,h5,h6")).map((h) => h.tagName.toLowerCase()),
    elements,
    focusables,
    candidates
  });
})()
"##;

const DISCOVER_JS: &str = r#"(() => {
  const out = [];
  const seen = new Set();
  const add = (el, kind) => {
    if (!el || seen.has(el)) return;
    seen.add(el);
    el.setAttribute("data-ui-scrape", String(out.length));
    const name = (el.getAttribute("aria-label") || el.innerText || el.getAttribute("title") || "").trim().slice(0, 80);
    out.push({ index: out.length, name, kind });
  };
  document.querySelectorAll("details:not([open]) > summary").forEach((el) => add(el, "details"));
  document.querySelectorAll('[aria-expanded="false"]').forEach((el) => add(el, "aria"));
  document.querySelectorAll('[role="tab"][aria-selected="false"]').forEach((el) => add(el, "tab"));
  return JSON.stringify(out);
})()"#;

fn activate_js(index: usize) -> String {
    format!(
        r#"(() => {{ const el = document.querySelector('[data-ui-scrape="{index}"]'); if (!el) return false; el.click(); return true; }})()"#
    )
}

fn activated_js(index: usize) -> String {
    format!(
        r#"(() => {{ const el = document.querySelector('[data-ui-scrape="{index}"]'); if (!el) return false; return el.getAttribute("aria-expanded") === "true" || el.getAttribute("aria-selected") === "true" || (el.tagName === "SUMMARY" && el.parentElement && el.parentElement.open === true); }})()"#
    )
}

struct Args {
    url: Option<String>,
    source: Option<PathBuf>,
    wait_for: Option<String>,
    width: u32,
    height: u32,
    timeout: Duration,
    state: String,
    theme: Option<String>,
    pretty: bool,
    chrome: Option<PathBuf>,
    no_sandbox: bool,
    expand: bool,
    max_states: usize,
}

fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err(error) => {
            eprintln!("ui-scrape: {error:#}");
            std::process::exit(1);
        }
    }
}

fn parse_args() -> Result<Args> {
    let mut url = None;
    let mut source = None;
    let mut wait_for = None;
    let mut width = 1280;
    let mut height = 800;
    let mut timeout = Duration::from_millis(15000);
    let mut state = String::from("default");
    let mut theme = None;
    let mut pretty = false;
    let mut no_sandbox = false;
    let mut expand = false;
    let mut max_states = 8usize;
    let mut chrome = std::env::var("UI_SCRAPE_CHROME")
        .or_else(|_| std::env::var("CHROME"))
        .ok()
        .map(PathBuf::from);

    let mut argv = std::env::args().skip(1);
    while let Some(arg) = argv.next() {
        match arg.as_str() {
            "--url" => url = Some(argv.next().context("--url needs a value")?),
            "--source" => source = Some(PathBuf::from(argv.next().context("--source needs a path")?)),
            "--wait-for" => wait_for = Some(argv.next().context("--wait-for needs a value")?),
            "--state" => state = argv.next().context("--state needs a value")?,
            "--theme" => theme = Some(argv.next().context("--theme needs light or dark")?),
            "--viewport" => {
                let raw = argv.next().context("--viewport needs WxH")?;
                let (w, h) = raw.split_once('x').context("--viewport must be WxH")?;
                width = w.parse().context("bad viewport width")?;
                height = h.parse().context("bad viewport height")?;
            }
            "--timeout" => {
                let raw = argv.next().context("--timeout needs milliseconds")?;
                timeout = Duration::from_millis(raw.parse().context("bad timeout")?);
            }
            "--chrome" => chrome = Some(PathBuf::from(argv.next().context("--chrome needs a path")?)),
            "--no-sandbox" => no_sandbox = true,
            "--expand" => expand = true,
            "--max-states" => {
                max_states = argv
                    .next()
                    .context("--max-states needs a count")?
                    .parse()
                    .context("bad max-states")?
            }
            "--pretty" => pretty = true,
            "--help" | "-h" => {
                println!(
                    "usage: ui-scrape --url URL [options]\n       ui-scrape --source DIR [--pretty]\n\noptions: --wait-for SELECTOR --viewport WxH --timeout MS --state NAME --theme light|dark\n         --chrome PATH --no-sandbox --expand --max-states N"
                );
                std::process::exit(0);
            }
            other => anyhow::bail!("unknown argument: {other}"),
        }
    }

    if url.is_none() && source.is_none() {
        anyhow::bail!("--url or --source is required");
    }

    Ok(Args {
        url,
        source,
        wait_for,
        width,
        height,
        timeout,
        state,
        theme,
        pretty,
        chrome,
        no_sandbox,
        expand,
        max_states,
    })
}

fn run() -> Result<i32> {
    let args = parse_args()?;

    if let Some(root) = &args.source {
        return source_mode(root, args.pretty);
    }

    let mut builder = LaunchOptions::default_builder();
    builder
        .headless(true)
        .sandbox(!args.no_sandbox)
        .window_size(Some((args.width, args.height)))
        .idle_browser_timeout(Duration::from_secs(30));
    if let Some(path) = &args.chrome {
        builder.path(Some(path.clone()));
    }
    builder.args(vec![
        OsStr::new("--disable-dev-shm-usage"),
        OsStr::new("--hide-scrollbars"),
        OsStr::new("--force-color-profile=srgb"),
    ]);

    let browser = Browser::new(builder.build()?).context("launch chromium")?;
    let tab = browser.new_tab().context("open tab")?;
    tab.set_default_timeout(args.timeout);
    tab.call_method(Emulation::SetDeviceMetricsOverride {
        width: args.width,
        height: args.height,
        device_scale_factor: 1.0,
        mobile: args.width < 600,
        scale: None,
        screen_width: Some(args.width),
        screen_height: Some(args.height),
        position_x: None,
        position_y: None,
        dont_set_visible_size: None,
        screen_orientation: None,
        viewport: None,
        display_feature: None,
        device_posture: None,
    })
    .context("set device metrics")?;

    if let Some(theme) = &args.theme {
        tab.call_method(Emulation::SetEmulatedMedia {
            media: None,
            features: Some(vec![Emulation::MediaFeature {
                name: "prefers-color-scheme".to_string(),
                value: theme.clone(),
            }]),
        })
        .context("set emulated media")?;
    }

    load(&tab, &args)?;
    let baseline = evaluate(&tab)?;
    let mut findings = with_state(check(&baseline), &args.state);
    let baseline_keys: HashSet<String> = findings.iter().map(finding_key).collect();
    let mut expanded: Vec<Value> = Vec::new();
    let mut skipped: Vec<Value> = Vec::new();

    if args.expand {
        let discovered = evaluate_js(&tab, DISCOVER_JS)?;
        for candidate in discovered.as_array().cloned().unwrap_or_default() {
            let name = candidate["name"].as_str().unwrap_or("").trim().to_string();
            let index = candidate["index"].as_u64().unwrap_or(0) as usize;
            let kind = candidate["kind"].clone();

            if is_destructive(&name) {
                skipped.push(json!({ "name": name, "reason": "destructive" }));
                continue;
            }
            if expanded.len() >= args.max_states {
                skipped.push(json!({ "name": name, "reason": "max-states" }));
                continue;
            }

            load(&tab, &args)?;
            let fresh = evaluate_js(&tab, DISCOVER_JS)?;
            let available = fresh.as_array().map(|list| list.len()).unwrap_or(0);
            if index >= available {
                skipped.push(json!({ "name": name, "reason": "not-found" }));
                continue;
            }
            if !evaluate_js(&tab, &activate_js(index))?
                .as_bool()
                .unwrap_or(false)
            {
                skipped.push(json!({ "name": name, "reason": "not-clickable" }));
                continue;
            }

            let mut activated = false;
            for _ in 0..20 {
                if evaluate_js(&tab, &activated_js(index))?
                    .as_bool()
                    .unwrap_or(false)
                {
                    activated = true;
                    break;
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            std::thread::sleep(Duration::from_millis(250));

            let state_data = evaluate(&tab)?;
            let state_findings = check(&state_data);
            let delta: Vec<Value> = state_findings
                .into_iter()
                .filter(|finding| !baseline_keys.contains(&finding_key(finding)))
                .collect();
            let state_name = slug(&name, index);
            let state_count = delta.len();
            findings.extend(with_state(delta, &state_name));
            expanded.push(json!({
                "name": state_name,
                "kind": kind,
                "activated": activated,
                "findings": state_count
            }));
        }
    }

    let candidates = baseline["candidates"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    let elements = baseline["elements"]
        .as_array()
        .map(|list| list.len())
        .unwrap_or(0);
    let mut by_check: serde_json::Map<String, Value> = serde_json::Map::new();
    for finding in &findings {
        let name = finding["check"].as_str().unwrap_or("unknown").to_string();
        let count = by_check.get(&name).and_then(Value::as_u64).unwrap_or(0);
        by_check.insert(name, json!(count + 1));
    }

    let report = json!({
        "tool": "ui-scrape",
        "version": env!("CARGO_PKG_VERSION"),
        "state": args.state,
        "theme": args.theme,
        "states": {
            "baseline": args.state,
            "expanded": expanded,
            "skipped": skipped
        },
        "url": baseline["url"],
        "title": baseline["title"],
        "lang": baseline["lang"],
        "viewport": baseline["viewport"],
        "scheme": baseline["scheme"],
        "reducedMotion": baseline["reducedMotion"],
        "summary": {
            "findings": findings.len(),
            "elements": elements,
            "byCheck": by_check
        },
        "findings": findings,
        "candidates": candidates,
        "focusOrder": baseline["focusables"],
        "unverified": unverified(&baseline)
    });

    if args.pretty {
        println!("{}", serde_json::to_string_pretty(&report)?);
    } else {
        println!("{}", serde_json::to_string(&report)?);
    }

    Ok(if findings.is_empty() { 0 } else { 2 })
}

const SOURCE_RULES: &[(&str, &str, &str, &str)] = &[
    (
        "raw-color",
        "P2",
        "raw color literal",
        r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(",
    ),
    (
        "outline-none",
        "P2",
        "focus outline suppressed",
        r"outline:\s*none|outline-none",
    ),
    (
        "transition-all",
        "P3",
        "transition on every property",
        r"transition-all|transition:\s*all",
    ),
    (
        "will-change",
        "P3",
        "manual compositor hint",
        r"will-change",
    ),
    (
        "gradient-text",
        "P3",
        "gradient text",
        r"bg-clip-text|text-transparent",
    ),
    (
        "glass",
        "P3",
        "decorative blur",
        r"backdrop-blur|backdrop-filter",
    ),
    ("viewport-width", "P3", "100vw sizing", r"100vw"),
    (
        "arbitrary-px",
        "P3",
        "arbitrary pixel value",
        r"\[[0-9]+px\]",
    ),
    (
        "clickable-div",
        "P2",
        "click handler on a non-control",
        r"<(div|span)[^>]*(onClick|@click)",
    ),
    (
        "motion",
        "P3",
        "motion declaration",
        r"@keyframes|animation:|animate-",
    ),
];

fn source_mode(root: &Path, pretty: bool) -> Result<i32> {
    let rules: Vec<(&str, &str, &str, Regex)> = SOURCE_RULES
        .iter()
        .map(|(id, severity, message, pattern)| {
            Ok((
                *id,
                *severity,
                *message,
                Regex::new(pattern).context("compile source rule")?,
            ))
        })
        .collect::<Result<_>>()?;

    let mut findings = Vec::new();
    let mut scanned = 0usize;
    for path in source_files(root).iter().filter(|path| is_ui_file(path)) {
        let Ok(content) = std::fs::read_to_string(path) else {
            continue;
        };
        scanned += 1;
        let relative = path
            .strip_prefix(root)
            .unwrap_or(path)
            .to_string_lossy()
            .to_string();
        for (line_number, line) in content.lines().enumerate() {
            for (id, severity, message, regex) in &rules {
                if regex.is_match(line) {
                    findings.push(json!({
                        "check": id,
                        "severity": severity,
                        "file": relative,
                        "line": line_number + 1,
                        "message": message,
                        "evidence": {
                            "text": line.trim().chars().take(160).collect::<String>()
                        }
                    }));
                }
            }
        }
    }

    findings.sort_by_key(|finding| match finding["severity"].as_str().unwrap_or("P3") {
        "P0" => 0,
        "P1" => 1,
        "P2" => 2,
        _ => 3,
    });

    let mut by_check: serde_json::Map<String, Value> = serde_json::Map::new();
    for finding in &findings {
        let name = finding["check"].as_str().unwrap_or("unknown").to_string();
        let count = by_check.get(&name).and_then(Value::as_u64).unwrap_or(0);
        by_check.insert(name, json!(count + 1));
    }

    let report = json!({
        "tool": "ui-scrape",
        "version": env!("CARGO_PKG_VERSION"),
        "mode": "source",
        "root": root,
        "summary": {
            "findings": findings.len(),
            "files": scanned,
            "byCheck": by_check
        },
        "findings": findings
    });

    if pretty {
        println!("{}", serde_json::to_string_pretty(&report)?);
    } else {
        println!("{}", serde_json::to_string(&report)?);
    }

    Ok(if report["findings"].as_array().map(|list| list.is_empty()).unwrap_or(true) {
        0
    } else {
        2
    })
}

fn source_files(root: &Path) -> Vec<PathBuf> {
    if let Some(output) = git_output(
        root,
        &[
            "diff",
            "--name-only",
            "--diff-filter=ACMRTUXB",
            "HEAD",
            "--",
            ".",
        ],
    ) {
        let mut files: Vec<PathBuf> = output
            .lines()
            .filter(|line| !line.trim().is_empty())
            .map(|line| root.join(line))
            .collect();
        if let Some(untracked) = git_output(root, &["ls-files", "--others", "--exclude-standard"]) {
            files.extend(
                untracked
                    .lines()
                    .filter(|line| !line.trim().is_empty())
                    .map(|line| root.join(line)),
            );
        }
        files.sort();
        files.dedup();
        return files;
    }

    let mut files = Vec::new();
    walk(root, &mut files, 0);
    files
}

fn git_output(root: &Path, args: &[&str]) -> Option<String> {
    let output = Command::new("git")
        .arg("-C")
        .arg(root)
        .args(args)
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    Some(String::from_utf8_lossy(&output.stdout).into_owned())
}

fn walk(dir: &Path, out: &mut Vec<PathBuf>, depth: usize) {
    if depth > 8 {
        return;
    }
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();
        if path.is_dir() {
            if matches!(
                name.as_str(),
                "node_modules" | ".git" | "dist" | "build" | "target" | ".next" | "vendor"
            ) {
                continue;
            }
            walk(&path, out, depth + 1);
        } else if path.is_file() {
            out.push(path);
        }
    }
}

fn is_ui_file(path: &Path) -> bool {
    let text = path.to_string_lossy();
    let extension = path.extension().and_then(|value| value.to_str()).unwrap_or("");
    matches!(
        extension,
        "tsx" | "jsx" | "vue" | "svelte" | "astro" | "html" | "css" | "scss" | "sass" | "less"
    ) || (matches!(extension, "ts" | "js")
        && ["/components/", "/pages/", "/views/", "/ui/", "/styles/", "/app/"]
            .iter()
            .any(|dir| text.contains(dir)))
}

fn load(tab: &Tab, args: &Args) -> Result<()> {
    let url = args.url.as_deref().context("--url is required")?;
    tab.navigate_to(url)
        .with_context(|| format!("navigate to {url}"))?;
    tab.wait_until_navigated().context("wait for navigation")?;
    if let Some(selector) = &args.wait_for {
        tab.wait_for_element_with_custom_timeout(selector, args.timeout)
            .with_context(|| format!("wait for {selector}"))?;
    }
    std::thread::sleep(Duration::from_millis(400));
    Ok(())
}

fn evaluate(tab: &Tab) -> Result<Value> {
    evaluate_js(tab, JS)
}

fn evaluate_js(tab: &Tab, js: &str) -> Result<Value> {
    let remote = tab.evaluate(js, true).context("evaluate page")?;
    let raw = remote.value.context("page returned no value")?;
    match raw {
        Value::String(text) => serde_json::from_str(&text).context("parse page payload"),
        other => Ok(other),
    }
}

fn with_state(findings: Vec<Value>, state: &str) -> Vec<Value> {
    findings
        .into_iter()
        .map(|mut finding| {
            if let Some(object) = finding.as_object_mut() {
                object.insert("state".to_string(), json!(state));
            }
            finding
        })
        .collect()
}

fn finding_key(finding: &Value) -> String {
    format!(
        "{}|{}",
        finding["check"].as_str().unwrap_or(""),
        finding["selector"].as_str().unwrap_or("")
    )
}

fn is_destructive(name: &str) -> bool {
    let name = name.to_lowercase();
    [
        "delete",
        "remove",
        "pay",
        "buy",
        "send",
        "submit",
        "logout",
        "sign out",
        "unsubscribe",
        "publish",
    ]
    .iter()
    .any(|word| name.contains(word))
}

fn slug(name: &str, index: usize) -> String {
    let mut out = String::new();
    for character in name.chars() {
        if character.is_ascii_alphanumeric() {
            out.push(character.to_ascii_lowercase());
        } else if !out.ends_with('-') {
            out.push('-');
        }
    }
    let out = out.trim_matches('-').to_string();
    if out.is_empty() {
        format!("unnamed-{index}")
    } else {
        out
    }
}

fn unverified(data: &Value) -> Vec<Value> {
    let mut out = Vec::new();
    if let Some(elements) = data["elements"].as_array() {
        let unknown: Vec<&Value> = elements
            .iter()
            .filter(|e| e["background"]["unknown"].is_string())
            .collect();
        if !unknown.is_empty() {
            out.push(json!({
                "check": "contrast",
                "reason": "background image or gradient behind text",
                "elements": unknown.len()
            }));
        }
    }
    out
}

fn check(data: &Value) -> Vec<Value> {
    let mut findings: Vec<Value> = Vec::new();
    let elements = data["elements"].as_array().cloned().unwrap_or_default();

    if let Some(viewport) = data["viewport"].as_object() {
        let width = viewport.get("width").and_then(Value::as_f64).unwrap_or(0.0);
        let document_width = viewport
            .get("documentWidth")
            .and_then(Value::as_f64)
            .unwrap_or(0.0);
        if document_width > width + 1.0 {
            findings.push(json!({
                "check": "page-overflow",
                "severity": "P1",
                "selector": "html",
                "message": format!("document is {document_width:.0}px wide in a {width:.0}px viewport"),
                "evidence": { "documentWidth": document_width, "viewportWidth": width }
            }));
        }
    }

    if data["lang"].is_null() {
        findings.push(json!({
            "check": "missing-lang",
            "severity": "P2",
            "selector": "html",
            "message": "html element has no lang attribute",
            "evidence": {}
        }));
    }

    let mut previous_heading = 0u32;
    for heading in data["headings"].as_array().cloned().unwrap_or_default() {
        let level = heading
            .as_str()
            .and_then(|h| h.strip_prefix('h'))
            .and_then(|n| n.parse::<u32>().ok())
            .unwrap_or(0);
        if level == 0 {
            continue;
        }
        if previous_heading > 0 && level > previous_heading + 1 {
            findings.push(json!({
                "check": "heading-skip",
                "severity": "P3",
                "selector": format!("h{level}"),
                "message": format!("heading level jumps from h{previous_heading} to h{level}"),
                "evidence": { "from": previous_heading, "to": level }
            }));
        }
        previous_heading = level;
    }

    for focusable in data["focusables"].as_array().cloned().unwrap_or_default() {
        if let Some(hidden) = focusable["hiddenBy"].as_str() {
            findings.push(json!({
                "check": "focus-hidden",
                "severity": "P2",
                "selector": focusable["selector"],
                "message": format!("focusable element is hidden by {hidden}"),
                "evidence": {
                    "tabIndex": focusable["tabIndex"],
                    "name": focusable["name"]
                }
            }));
        }
    }

    for element in elements {
        let selector = element["selector"].as_str().unwrap_or("?");
        let tag = element["tag"].as_str().unwrap_or("?");
        let interactive = element["interactive"].as_bool().unwrap_or(false);
        let disabled = element["disabled"].as_bool().unwrap_or(false);
        let has_text = element["hasText"].as_bool().unwrap_or(false);
        let name = element["name"].as_str().unwrap_or("").trim().to_string();
        let rect_w = element["rect"]["w"].as_f64().unwrap_or(0.0);
        let rect_h = element["rect"]["h"].as_f64().unwrap_or(0.0);

        if interactive && !disabled && name.is_empty() {
            findings.push(json!({
                "check": "missing-name",
                "severity": "P1",
                "selector": selector,
                "message": format!("{tag} has no accessible name"),
                "evidence": { "tag": tag }
            }));
        }

        if interactive && !disabled && (rect_w < 44.0 || rect_h < 44.0) {
            findings.push(json!({
                "check": "target-size",
                "severity": "P2",
                "selector": selector,
                "message": format!("target is {rect_w:.0}x{rect_h:.0}px, below 44x44"),
                "evidence": { "width": rect_w, "height": rect_h }
            }));
        }

        if let Some(raw) = element["tabindex"].as_str() {
            if raw.parse::<i32>().map(|n| n > 0).unwrap_or(false) {
                findings.push(json!({
                    "check": "positive-tabindex",
                    "severity": "P3",
                    "selector": selector,
                    "message": format!("tabindex={raw} overrides document order"),
                    "evidence": { "tabindex": raw }
                }));
            }
        }

        if has_text {
            if let Some(ratio) = contrast_ratio(&element) {
                let font_size = element["fontSize"].as_f64().unwrap_or(16.0);
                let font_weight = element["fontWeight"].as_u64().unwrap_or(400);
                let large = font_size >= 24.0 || (font_size >= 18.66 && font_weight >= 700);
                let threshold = if large { 3.0 } else { 4.5 };
                if ratio < threshold {
                    findings.push(json!({
                        "check": "contrast",
                        "severity": "P2",
                        "selector": selector,
                        "message": format!("text contrast {ratio:.2}:1 is below {threshold:.1}:1"),
                        "evidence": {
                            "ratio": (ratio * 100.0).round() / 100.0,
                            "threshold": threshold,
                            "color": element["color"],
                            "fontSize": font_size,
                            "fontWeight": font_weight,
                            "text": element["text"]
                        }
                    }));
                }
            }
        }

        let overflow_x = element["overflowX"].as_i64().unwrap_or(0);
        let overflow_y = element["overflowY"].as_i64().unwrap_or(0);
        let overflow = element["overflow"].as_str().unwrap_or("");
        let clips = overflow.contains("hidden") || overflow.contains("clip");
        if clips && has_text && (overflow_x > 1 || overflow_y > 1) {
            findings.push(json!({
                "check": "clipped-text",
                "severity": "P2",
                "selector": selector,
                "message": format!("text is clipped by {overflow}"),
                "evidence": {
                    "overflowX": overflow_x,
                    "overflowY": overflow_y,
                    "textOverflow": element["textOverflow"],
                    "whiteSpace": element["whiteSpace"]
                }
            }));
        }
    }

    findings.sort_by_key(|finding| match finding["severity"].as_str().unwrap_or("P3") {
        "P0" => 0,
        "P1" => 1,
        "P2" => 2,
        _ => 3,
    });
    findings
}

fn contrast_ratio(element: &Value) -> Option<f64> {
    let (fr, fg, fb, fa) = parse_css_color(element["color"].as_str()?)?;
    let background = element["background"].as_object()?;
    let br = background.get("r")?.as_f64()?;
    let bg = background.get("g")?.as_f64()?;
    let bb = background.get("b")?.as_f64()?;

    let fg_composited = (
        fr * fa + br * (1.0 - fa),
        fg * fa + bg * (1.0 - fa),
        fb * fa + bb * (1.0 - fa),
    );
    let foreground = luminance(fg_composited.0, fg_composited.1, fg_composited.2);
    let backdrop = luminance(br, bg, bb);
    let (lighter, darker) = if foreground > backdrop {
        (foreground, backdrop)
    } else {
        (backdrop, foreground)
    };
    Some((lighter + 0.05) / (darker + 0.05))
}

fn parse_css_color(css: &str) -> Option<(f64, f64, f64, f64)> {
    let css = css.trim();
    let inner = css
        .strip_prefix("rgba(")
        .or_else(|| css.strip_prefix("rgb("))?
        .strip_suffix(')')?;
    let parts: Vec<f64> = inner
        .split([',', '/', ' '])
        .filter(|part| !part.trim().is_empty())
        .filter_map(|part| part.trim().parse::<f64>().ok())
        .collect();
    if parts.len() < 3 {
        return None;
    }
    Some((
        parts[0],
        parts[1],
        parts[2],
        *parts.get(3).unwrap_or(&1.0),
    ))
}

fn luminance(r: f64, g: f64, b: f64) -> f64 {
    0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

fn channel(value: f64) -> f64 {
    let value = value / 255.0;
    if value <= 0.03928 {
        value / 12.92
    } else {
        ((value + 0.055) / 1.055).powf(2.4)
    }
}
