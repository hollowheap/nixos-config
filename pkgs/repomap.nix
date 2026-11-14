{
  writers,
  lib,
  universal-ctags,
  fd,
  git,
  makeWrapper,
  symlinkJoin,
}:
let
  repomapScript = writers.writePython3Bin "repomap" {
    flakeIgnore = [ "E501" "E302" "E305" "W293" "W291" ];
  } ''
    import argparse
    from collections import defaultdict
    import hashlib
    import json
    import os
    from pathlib import Path
    import subprocess
    import sys
    import tempfile

    CACHE_VERSION = 2
    EXCLUDED_NAMES = {".git", "node_modules", "result", "flake.lock"}


    def parse_args():
        parser = argparse.ArgumentParser(
            description="Generate an AST-aware repository symbol map for AI agents."
        )
        parser.add_argument(
            "path",
            nargs="?",
            default=".",
            help="Directory or file to map (default: current directory)",
        )
        parser.add_argument(
            "--max-lines",
            type=int,
            default=200,
            help="Maximum lines of output (default: 200)",
        )
        parser.add_argument(
            "--exts",
            nargs="+",
            default=None,
            help="Filter file extensions (e.g. nix py rs ts lua)",
        )
        parser.add_argument(
            "--output",
            default=None,
            help="Write the map to this file instead of stdout.",
        )
        return parser.parse_args()


    def stat_sig(path):
        try:
            if path.is_symlink() or not path.is_file():
                return None
            st = path.stat()
        except OSError:
            return None
        return [st.st_mtime_ns, st.st_size]


    def is_excluded(path, target, output_path):
        if output_path is not None and path == output_path:
            return True
        try:
            rel_parts = path.relative_to(target).parts if target.is_dir() else (path.name,)
        except ValueError:
            rel_parts = path.parts
        return any(part in EXCLUDED_NAMES for part in rel_parts)


    def matches_exts(path, exts):
        return not exts or path.suffix.lstrip(".").lower() in exts


    def cache_file_for(target, exts):
        base = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "repomap"
        payload = json.dumps({"v": CACHE_VERSION, "target": str(target), "exts": exts}, sort_keys=True)
        digest = hashlib.sha256(payload.encode()).hexdigest()[:24]
        return base / f"{digest}.json"


    def load_cache(cache_path):
        try:
            data = json.loads(cache_path.read_text())
        except (OSError, ValueError):
            return None
        if all((
            isinstance(data, dict),
            data.get("version") == CACHE_VERSION,
            isinstance(data.get("files"), dict),
        )):
            return data
        return None


    def atomic_write_text(path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        fd_num, tmp_name = tempfile.mkstemp(prefix=".repomap-", dir=str(path.parent))
        try:
            umask = os.umask(0o022)
            os.umask(umask)
            os.fchmod(fd_num, 0o666 & ~umask)
            with os.fdopen(fd_num, "w", encoding="utf-8") as fh:
                fh.write(text)
            os.replace(tmp_name, path)
        except Exception:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
            raise


    def save_cache(cache_path, cache):
        try:
            atomic_write_text(cache_path, json.dumps(cache, separators=(",", ":")))
        except OSError:
            pass


    def git_context(target):
        cwd = target if target.is_dir() else target.parent
        try:
            res = subprocess.run(
                ["git", "-C", str(cwd), "rev-parse", "--show-toplevel", "HEAD"],
                capture_output=True,
                text=True,
                check=True,
            )
        except (OSError, subprocess.CalledProcessError):
            return None
        lines = res.stdout.splitlines()
        if len(lines) < 2:
            return None
        git_root = Path(lines[0]).resolve()
        try:
            target.relative_to(git_root)
        except ValueError:
            return None
        return git_root, lines[1].strip()


    def git_dirty_paths(git_root, rel_target, output_path):
        try:
            res = subprocess.run(
                ["git", "-C", str(git_root), "status", "--porcelain=v1", "-z", "-uall", "--", rel_target],
                capture_output=True,
                check=True,
            )
        except (OSError, subprocess.CalledProcessError):
            return None

        entries = res.stdout.split(b"\0")
        paths = []
        idx = 0
        while idx < len(entries):
            item = entries[idx]
            idx += 1
            if not item or len(item) < 4:
                continue
            status = item[:2]
            rel = item[3:].decode("utf-8", errors="surrogateescape")
            if rel.endswith("/") or os.path.basename(rel) == ".gitignore":
                return None
            abs_p = (git_root / rel).resolve()
            if output_path is None or abs_p != output_path:
                paths.append(str(abs_p))
            if status[:1] in (b"R", b"C") or status[1:2] in (b"R", b"C"):
                if idx < len(entries) and entries[idx]:
                    orig = entries[idx].decode("utf-8", errors="surrogateescape")
                    paths.append(str((git_root / orig).resolve()))
                idx += 1
        return sorted(set(paths))


    def git_commit_diff_paths(git_root, rel_target, old_head, new_head):
        if old_head == new_head:
            return []
        try:
            res = subprocess.run(
                ["git", "-C", str(git_root), "diff", "--name-only", "--no-renames", "-z", old_head, new_head, "--", rel_target],
                capture_output=True,
                check=True,
            )
        except (OSError, subprocess.CalledProcessError):
            return None

        paths = []
        for chunk in res.stdout.split(b"\0"):
            if not chunk:
                continue
            rel = chunk.decode("utf-8", errors="surrogateescape")
            if os.path.basename(rel) == ".gitignore":
                return None
            paths.append(str((git_root / rel).resolve()))
        return paths


    def get_files_fd(root, exts, output_path):
        cmd = [
            "fd",
            "--type",
            "f",
            "--hidden",
            "--exclude",
            ".git",
            "--exclude",
            "node_modules",
            "--exclude",
            "result",
            "--exclude",
            "flake.lock",
        ]
        for ext in exts:
            cmd.extend(["-e", ext])
        cmd.extend(["", str(root)])
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        except (OSError, subprocess.CalledProcessError):
            return []

        files = []
        for line in res.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            p = Path(line).resolve()
            if not is_excluded(p, root, output_path):
                files.append(p)
        return files


    def get_tags(files):
        if not files:
            return {}
        cmd = [
            "ctags",
            "--langdef=Nix",
            "--map-Nix=+.nix",
            "--regex-Nix=/^[ \\t]*options\\.([a-zA-Z0-9_.-]+)[ \\t]*=/\\1/o,option/",
            "--regex-Nix=/^[ \\t]*config\\.([a-zA-Z0-9_.-]+)[ \\t]*=/\\1/c,config/",
            "--regex-Nix=/^[ \\t]*([a-zA-Z0-9_-]+)[ \\t]*=[ \\t]*(mk[A-Za-z0-9_]+|rec|\\{)/\\1/v,definition/",
            "--fields=+n+k+S",
            "--output-format=json",
            "-L",
            "-",
        ]
        try:
            res = subprocess.run(cmd, input="\n".join(files), capture_output=True, text=True, check=False)
        except OSError as e:
            print(f"Error executing ctags: {e}", file=sys.stderr)
            return {}

        by_file = defaultdict(list)
        for line in res.stdout.splitlines():
            if not line.strip():
                continue
            try:
                tag = json.loads(line)
            except json.JSONDecodeError:
                continue
            path = tag.get("path")
            name = tag.get("name")
            if path and name:
                by_file[path].append([
                    tag.get("line", 1),
                    tag.get("kind", "sym"),
                    name,
                    tag.get("signature", ""),
                ])
        return by_file


    def render_map(path_label, cached_files, max_lines, cwd):
        output_lines = [f"# Codebase Outline ({path_label})", ""]
        limit = max(1, max_lines)
        truncation_msg = f"... [Truncated at {max_lines} lines. Use --max-lines to expand]"

        for filepath in sorted(cached_files.keys()):
            tags = cached_files[filepath].get("tags") or []
            if not tags:
                continue
            rel_path = os.path.relpath(filepath, cwd)
            symbols = sorted(tags, key=lambda x: (x[0], x[2]))
            block = [f"## {rel_path}"]
            for line_no, kind, name, sig in symbols:
                sig_str = f" {sig}" if sig else ""
                block.append(f"  - [{kind}] {name}{sig_str} (L{line_no})")
            block.append("")

            if len(output_lines) + len(block) > limit:
                remaining = max(0, limit - len(output_lines) - 1)
                if remaining > 1:
                    output_lines.extend(block[:remaining])
                output_lines.append(truncation_msg)
                break
            output_lines.extend(block)

        return "\n".join(output_lines)


    def main():
        args = parse_args()
        target = Path(args.path).resolve()
        output_path = Path(args.output).resolve() if args.output else None
        exts = sorted({s for e in (args.exts or []) if (s := e.lstrip(".").lower())})

        cache_path = cache_file_for(target, exts)
        cache = load_cache(cache_path) or {
            "version": CACHE_VERSION,
            "head": None,
            "dirty": [],
            "files": {},
        }
        cached_files = cache["files"]

        gctx = None if target.is_file() else git_context(target)
        cur_head = gctx[1] if gctx else None
        rel_target = os.path.relpath(target, gctx[0]) if gctx else None
        cur_dirty = git_dirty_paths(gctx[0], rel_target, output_path) if gctx else None

        removed = 0
        to_tag = {}
        used_git_diff = False

        if gctx and cur_dirty is not None and cache.get("head") and cached_files:
            diff_paths = git_commit_diff_paths(gctx[0], rel_target, cache["head"], cur_head)
            if diff_paths is not None:
                used_git_diff = True
                candidates = set(cur_dirty) | set(cache.get("dirty") or ()) | set(diff_paths)
                for path_str in candidates:
                    p = Path(path_str)
                    sig = None if (is_excluded(p, target, output_path) or not matches_exts(p, exts)) else stat_sig(p)
                    if sig is None:
                        if path_str in cached_files:
                            del cached_files[path_str]
                            removed += 1
                    else:
                        prev = cached_files.get(path_str)
                        if not prev or prev.get("sig") != sig:
                            to_tag[path_str] = sig

        if not used_git_diff:
            if target.is_file():
                raw_candidates = [] if is_excluded(target, target, output_path) or not matches_exts(target, exts) else [target]
            else:
                raw_candidates = get_files_fd(target, exts, output_path)
            current_set = set()
            for p in raw_candidates:
                path_str = str(p)
                sig = stat_sig(p)
                if sig is None:
                    continue
                current_set.add(path_str)
                prev = cached_files.get(path_str)
                if not prev or prev.get("sig") != sig:
                    to_tag[path_str] = sig
            for stale in [k for k in cached_files if k not in current_set]:
                del cached_files[stale]
                removed += 1

        if to_tag:
            tagged = get_tags(sorted(to_tag.keys()))
            for path_str, sig in to_tag.items():
                cached_files[path_str] = {"sig": sig, "tags": tagged.get(path_str, [])}

        retagged = len(to_tag)
        next_dirty = cur_dirty if cur_dirty is not None else []
        cwd = os.getcwd()
        cache_dirty = any((
            retagged > 0,
            removed > 0,
            cache.get("head") != cur_head,
            cache.get("dirty") != next_dirty,
        ))

        if output_path is not None:
            same_render = all((
                not retagged,
                not removed,
                output_path.exists(),
                cache.get("last_output") == str(output_path),
                cache.get("last_max_lines") == args.max_lines,
                cache.get("last_cwd") == cwd,
                cache.get("last_path") == args.path,
            ))
            if same_render:
                if cache_dirty:
                    cache["head"] = cur_head
                    cache["dirty"] = next_dirty
                    save_cache(cache_path, cache)
                return

            output = render_map(args.path, cached_files, args.max_lines, cwd) + "\n"
            try:
                existing = output_path.read_text() if output_path.exists() else None
            except OSError:
                existing = None
            if existing != output:
                atomic_write_text(output_path, output)
            cache["last_output"] = str(output_path)
            cache["last_max_lines"] = args.max_lines
            cache["last_cwd"] = cwd
            cache["last_path"] = args.path
            cache_dirty = True
        else:
            print(render_map(args.path, cached_files, args.max_lines, cwd))

        if cache_dirty:
            cache["head"] = cur_head
            cache["dirty"] = next_dirty
            save_cache(cache_path, cache)


    if __name__ == "__main__":
        main()
  '';
in
symlinkJoin {
  name = "repomap";
  paths = [ repomapScript ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/repomap \
      --prefix PATH : ${lib.makeBinPath [ universal-ctags fd git ]}
  '';
}
