// The crates.io launcher. vox-fuzz is written in Vox; crates.io ships Rust.
// This binary carries the Vox sources embedded (build.rs), and on first run
// materialises them to a versioned cache, compiles them with the vox
// compiler found on PATH, and execs the result — the same
// materialise-and-cache shape the vox compiler itself uses for its coreasm.
//
// The RPM and Nix packages ship the real compiled binary directly and never
// touch this file; this launcher exists so `cargo install vox-fuzz` works.

include!(concat!(env!("OUT_DIR"), "/vox_sources.rs"));

use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::{exit, Command};

const VERSION: &str = env!("CARGO_PKG_VERSION");

fn fail(msg: &str) -> ! {
    eprintln!("vox-fuzz: {msg}");
    exit(2);
}

fn find_vox() -> PathBuf {
    if let Ok(v) = env::var("VOX") {
        let p = PathBuf::from(v);
        if p.is_file() {
            return p;
        }
        fail("the VOX environment variable is set but does not point at a file");
    }
    // PATH lookup, resolved once so the cache records what compiled it.
    if let Ok(path) = env::var("PATH") {
        for dir in env::split_paths(&path) {
            let cand = dir.join("vox");
            if cand.is_file() {
                return cand;
            }
        }
    }
    fail(
        "no vox compiler found. vox-fuzz is written in Vox and needs the \
         compiler it tests:\n  dnf install vox        (Fedora/RHEL, Copr)\n  \
         cargo install vox-lang (crates.io)\nThen run vox-fuzz again.",
    );
}

fn cache_dir() -> PathBuf {
    let base = env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| env::var_os("HOME").map(|h| PathBuf::from(h).join(".cache")))
        .unwrap_or_else(|| fail("neither XDG_CACHE_HOME nor HOME is set"));
    base.join("vox-fuzz").join(VERSION)
}

fn main() {
    let cache = cache_dir();
    let bin = cache.join("vox-fuzz-bin");

    if !bin.is_file() {
        let vox = find_vox();
        let src = cache.join("src");
        // Write into a temp sibling and rename, so a half-written tree is
        // never observable and two racing first runs are harmless.
        let staging = cache.with_extension("staging");
        let _ = fs::remove_dir_all(&staging);
        let staged_src = staging.join("src");
        fs::create_dir_all(&staged_src)
            .unwrap_or_else(|e| fail(&format!("cannot create {}: {e}", staged_src.display())));
        for (name, body) in VOX_SOURCES {
            fs::write(staged_src.join(name), body)
                .unwrap_or_else(|e| fail(&format!("cannot write {name}: {e}")));
        }
        let staged_bin = staging.join("vox-fuzz-bin");
        let status = Command::new(&vox)
            .arg(staged_src.join("main.vox"))
            .arg("-o")
            .arg(&staged_bin)
            .status()
            .unwrap_or_else(|e| fail(&format!("cannot run {}: {e}", vox.display())));
        if !status.success() {
            fail(&format!(
                "the vox compiler ({}) failed to build the embedded sources — \
                 a version mismatch between vox-fuzz {VERSION} and your vox is \
                 the usual cause; try updating both",
                vox.display()
            ));
        }
        let _ = fs::remove_dir_all(&cache);
        if let Some(parent) = cache.parent() {
            let _ = fs::create_dir_all(parent);
        }
        fs::rename(&staging, &cache)
            .unwrap_or_else(|e| fail(&format!("cannot move the built cache into place: {e}")));
        let _ = src; // the materialised sources stay beside the binary for repro value
    }

    // Hand over entirely: the Vox binary is the program, this was only the porter.
    let args: Vec<String> = env::args().skip(1).collect();
    let status = Command::new(&bin)
        .args(&args)
        .status()
        .unwrap_or_else(|e| fail(&format!("cannot run the built vox-fuzz: {e}")));
    exit(status.code().unwrap_or(1));
}
