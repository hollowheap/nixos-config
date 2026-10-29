{
  writers,
  lib,
  universal-ctags,
  fd,
  makeWrapper,
  symlinkJoin,
}:
let
  repomapScript = writers.writePython3Bin "repomap" {
    flakeIgnore = [ "E501" "E302" "E305" "W293" "W291" ];
  } ''
    import argparse
    from collections import defaultdict
    import json
    import os
    from pathlib import Path
    import subprocess
    import sys


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


    def get_files(root, exts=None):
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
        if exts:
            for ext in exts:
                cmd.extend(["-e", ext.lstrip(".")])
        cmd.extend([".", root])
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return [line.strip() for line in res.stdout.splitlines() if line.strip()]
        except Exception:
            return []


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
            p = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            out, _ = p.communicate(input="\n".join(files))
            by_file = defaultdict(list)
            for line in out.splitlines():
                if not line.strip():
                    continue
                try:
                    tag = json.loads(line)
                    path = tag.get("path")
                    name = tag.get("name")
                    kind = tag.get("kind", "sym")
                    line_no = tag.get("line", 1)
                    sig = tag.get("signature", "")
                    if path and name:
                        by_file[path].append((line_no, kind, name, sig))
                except json.JSONDecodeError:
                    continue
            return by_file
        except Exception as e:
            print(f"Error executing ctags: {e}", file=sys.stderr)
            return {}


    def main():
        args = parse_args()
        target = Path(args.path).resolve()

        if target.is_file():
            files = [str(target)]
        else:
            files = get_files(str(target), args.exts)

        tags_by_file = get_tags(files)

        output_lines = [f"# Codebase Outline ({args.path})", ""]

        for filepath in sorted(tags_by_file.keys()):
            rel_path = os.path.relpath(filepath, os.getcwd())
            symbols = sorted(tags_by_file[filepath], key=lambda x: x[0])
            output_lines.append(f"## {rel_path}")
            for line_no, kind, name, sig in symbols:
                sig_str = f" {sig}" if sig else ""
                output_lines.append(f"  - [{kind}] {name}{sig_str} (L{line_no})")
            output_lines.append("")

            if len(output_lines) >= args.max_lines:
                output_lines.append(
                    f"... [Truncated at {args.max_lines} lines. Use --max-lines to expand]"
                )
                break

        output = "\n".join(output_lines)
        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(output + "\n")
        else:
            print(output)


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
      --prefix PATH : ${lib.makeBinPath [ universal-ctags fd ]}
  '';
}
