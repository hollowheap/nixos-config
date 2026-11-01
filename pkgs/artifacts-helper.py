#!/usr/bin/env python3
"""
artifacts-helper: RDST trace stack navigator and verifier.
Maintains the tree data structure of Requirements (REQ), Decisions (DEC),
Specifications (SPEC), and Tasks (TASK).

Enforces the completion invariant:
"The parent is only completed when all of its children are completed."
"""

import argparse
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


def normalize_id(raw: str) -> str:
    """Normalizes identifiers like REQ-01 -> R01, TASK-05 -> T05."""
    raw = raw.strip()
    if raw.startswith("REQ-"):
        return "R" + raw[4:]
    if raw.startswith("DEC-"):
        return "D" + raw[4:]
    if raw.startswith("SPEC-"):
        return "S" + raw[5:]
    if raw.startswith("TASK-"):
        return "T" + raw[5:]
    return raw


@dataclass
class Node:
    kind: str  # "REQ", "DEC", "SPEC", "TASK"
    id: str  # Normalized ID (e.g., "R01", "D22", "S43", "T05")
    raw_id: str  # As appeared in source file (e.g., "R01" or "REQ-01")
    checked: bool  # Checkbox state in markdown: True if [x], False if [ ]
    raw_header: str  # Original line text
    title: str  # Cleaned title description
    parent_ids: List[str] = field(default_factory=list)  # Referenced parent IDs
    blocked_by: List[str] = field(default_factory=list)  # For tasks: dependency task IDs
    verify_cmd: Optional[str] = None
    arch_section: Optional[str] = None
    section: str = ""
    resolves: List[str] = field(default_factory=list)
    details: List[str] = field(default_factory=list)  # Indented description lines
    file_path: Path = Path()
    line_number: int = 0

    # Bidirectional tree graph edges
    parents: List["Node"] = field(default_factory=list)
    children: List["Node"] = field(default_factory=list)

    def is_leaf(self) -> bool:
        return len(self.children) == 0

    def is_tree_completed(self) -> bool:
        """
        Recursive completion logic:
        - A leaf task is complete iff its checkbox is checked [x].
        - A parent node is complete iff it has children AND ALL children are tree-completed.
        - If a spec has no child tasks, its own checkbox governs if explicitly verified.
        """
        if self.kind == "TASK":
            return self.checked
        if not self.children:
            return self.checked
        return all(child.is_tree_completed() for child in self.children)


class ArtifactsRepository:
    def __init__(self, artifacts_dir: Optional[Path] = None):
        if artifacts_dir is None:
            env_dir = os.environ.get("ARTIFACTS_DIR")
            if env_dir:
                self.root = Path(env_dir)
            else:
                # Discover repo root
                cur = Path.cwd()
                while cur != cur.parent:
                    if (cur / "artifacts").is_dir():
                        self.root = cur / "artifacts"
                        break
                    cur = cur.parent
                else:
                    self.root = Path("artifacts")
        else:
            self.root = artifacts_dir

        self.nodes: Dict[str, Node] = {}
        self.reqs: List[Node] = []
        self.decs: List[Node] = []
        self.specs: List[Node] = []
        self.tasks: List[Node] = []
        self.task_file = "tasks.md" if (self.root / "tasks.md").is_file() else "plan.md"
        self.parse_all()

    def parse_file(self, file_name: str, kind: str) -> List[Node]:
        path = self.root / file_name
        if not path.is_file():
            return []

        header_re = re.compile(
            r"^[ \t]*-[ \t]*\[([ xX])\][ \t]+((?:REQ-|R|DEC-|D|SPEC-|S|TASK-|T)\d+)\b(.*?)$"
        )
        bracket_re = re.compile(
            r"\[((?:REQ-|R|DEC-|D|SPEC-|S|TASK-|T)\d+(?:\s*,\s*(?:REQ-|R|DEC-|D|SPEC-|S|TASK-|T)\d+)*)\]"
        )
        blocked_trailing_re = re.compile(
            r"\[((?:TASK-|T)\d+(?:\s*,\s*(?:TASK-|T)\d+)*)\]\s*(?=:|$)", re.IGNORECASE
        )
        legacy_blocked_re = re.compile(r"\(blocked-by:[ \t]*([^)]+)\)", re.IGNORECASE)
        verify_inline_re = re.compile(r"(?:\||^-)[ \t]*Verify:[ \t]*(.+)$", re.IGNORECASE)
        verify_detail_re = re.compile(r"^[ \t]*-[ \t]*Verify:[ \t]*(.+)$", re.IGNORECASE)
        arch_detail_re = re.compile(r"^[ \t]*-[ \t]*(?:Arch|Architecture):[ \t]*(.+)$", re.IGNORECASE)
        resolves_detail_re = re.compile(r"^[ \t]*-[ \t]*Resolves:[ \t]*(.+)$", re.IGNORECASE)

        nodes: List[Node] = []
        current: Optional[Node] = None
        section = ""

        lines = path.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, start=1):
            if line.startswith("### "):
                section = line[4:].strip()
                current = None
                continue
            if line.startswith("## ") or line.startswith("# "):
                section = ""
                current = None
                continue

            m = header_re.match(line)
            if m:
                checked = m.group(1).lower() == "x"
                raw_id = m.group(2)
                item_id = normalize_id(raw_id)
                rest = m.group(3)

                blocked_by = []
                b_match = blocked_trailing_re.search(rest)
                if b_match:
                    raw_deps = b_match.group(1)
                    rest = rest[: b_match.start()].rstrip()
                else:
                    b_match = legacy_blocked_re.search(rest)
                    if b_match:
                        raw_deps = b_match.group(1)
                        rest = legacy_blocked_re.sub("", rest)
                    else:
                        raw_deps = ""

                for dep in re.split(r"[, \t]+", raw_deps.strip()):
                    dep = dep.strip()
                    if dep and dep.lower() != "none":
                        blocked_by.append(normalize_id(dep))

                parent_ids = []
                for group in bracket_re.findall(rest):
                    for part in re.split(r"\s*,\s*", group):
                        part = part.strip()
                        if part:
                            parent_ids.append(normalize_id(part))

                verify_cmd = None
                v_match = verify_inline_re.search(rest)
                if v_match:
                    verify_cmd = v_match.group(1).strip()

                title = rest
                title = bracket_re.sub("", title)
                if verify_cmd:
                    title = verify_inline_re.sub("", title)
                title = title.strip().lstrip(":").strip().rstrip("|").strip()

                current = Node(
                    kind=kind,
                    id=item_id,
                    raw_id=raw_id,
                    checked=checked,
                    raw_header=line,
                    title=title,
                    parent_ids=parent_ids,
                    blocked_by=blocked_by,
                    verify_cmd=verify_cmd,
                    section=section,
                    file_path=path,
                    line_number=idx,
                )
                nodes.append(current)
            elif current and (line.startswith("  ") or line.startswith("\t") or line.strip() == ""):
                if line.strip():
                    current.details.append(line)
                    v_match = verify_detail_re.search(line)
                    if v_match and not current.verify_cmd:
                        current.verify_cmd = v_match.group(1).strip()
                    a_match = arch_detail_re.search(line)
                    if a_match and not current.arch_section:
                        current.arch_section = a_match.group(1).strip().strip("`").strip()
                    r_match = resolves_detail_re.search(line)
                    if r_match:
                        for resolved in re.split(r"[,\s]+", r_match.group(1).strip()):
                            if resolved and resolved.lower() != "none":
                                current.resolves.append(normalize_id(resolved))
            else:
                current = None

        return nodes

    def parse_all(self):
        self.nodes.clear()
        self.reqs = self.parse_file("requirements.md", "REQ")
        self.decs = self.parse_file("decisions.md", "DEC")
        self.specs = self.parse_file("specs.md", "SPEC")
        self.tasks = self.parse_file(self.task_file, "TASK")

        for node in self.reqs + self.decs + self.specs + self.tasks:
            self.nodes[node.id] = node

        # Build tree edges
        # Tasks -> Specs
        for task in self.tasks:
            for pid in task.parent_ids:
                if pid in self.nodes:
                    parent = self.nodes[pid]
                    task.parents.append(parent)
                    parent.children.append(task)

        # Specs -> Decisions (or Requirements fallback)
        for spec in self.specs:
            linked = False
            for pid in spec.parent_ids:
                if pid in self.nodes:
                    parent = self.nodes[pid]
                    if parent.kind == "DEC":
                        spec.parents.append(parent)
                        parent.children.append(spec)
                        linked = True
            if not linked:
                for pid in spec.parent_ids:
                    if pid in self.nodes:
                        parent = self.nodes[pid]
                        if parent.kind == "REQ":
                            spec.parents.append(parent)
                            parent.children.append(spec)

        # Decisions -> Requirements
        for dec in self.decs:
            for pid in dec.parent_ids:
                if pid in self.nodes:
                    parent = self.nodes[pid]
                    dec.parents.append(parent)
                    parent.children.append(dec)

    def print_block(self, node: Node, show_location: bool = False):
        if show_location and node.file_path and node.line_number:
            print(f"<!-- {node.file_path.name}:{node.line_number} -->")
        print(node.raw_header)
        for d in node.details:
            print(d)

    # Subcommands
    def cmd_status(self):
        context_file = self.root / "context.md"
        context_status = "present" if context_file.is_file() and context_file.stat().st_size > 0 else "none"

        open_reqs = [r for r in self.reqs if not (r.checked and r.is_tree_completed())]
        open_decs = [d for d in self.decs if not (d.checked and d.is_tree_completed())]
        open_specs = [s for s in self.specs if not (s.checked and s.is_tree_completed())]
        open_tasks = [t for t in self.tasks if not (t.checked and t.is_tree_completed())]

        print(
            f"CONTEXT:{context_status} "
            f"REQ:{len(open_reqs)} "
            f"DEC:{len(open_decs)} "
            f"SPEC:{len(open_specs)} "
            f"TASK:{len(open_tasks)}"
        )

    def cmd_unconverted_reqs(self):
        unconverted = [r for r in self.reqs if not r.children and not r.checked]
        if not unconverted:
            print("NONE")
        else:
            for r in unconverted:
                print(r.raw_header)

    def cmd_unconverted_decs(self):
        unconverted = [d for d in self.decs if not d.children and not d.checked]
        if not unconverted:
            print("NONE")
        else:
            for d in unconverted:
                print(d.raw_header)

    def cmd_unconverted_specs(self):
        unconverted = [s for s in self.specs if not s.children and not s.checked]
        if not unconverted:
            print("NONE")
        else:
            for s in unconverted:
                print(s.raw_header)

    def cmd_frontier(self):
        done_ids = {t.id for t in self.tasks if t.checked}
        ready = []
        for t in self.tasks:
            if not t.checked:
                # Check blocked-by
                if not t.blocked_by or all(dep in done_ids for dep in t.blocked_by):
                    ready.append(t)

        if not ready:
            print("NONE")
        else:
            for t in ready:
                loc = f" ({t.file_path.name}:{t.line_number})" if t.file_path and t.line_number else ""
                print(f"{t.raw_header}{loc}")

    def next_id(self, kind_arg: str) -> str:
        k = kind_arg.lower()
        if k in ("r", "req", "requirement"):
            prefix = "R"
            nodes = self.reqs
        elif k in ("d", "dec", "decision"):
            prefix = "D"
            nodes = self.decs
        elif k in ("s", "spec"):
            prefix = "S"
            nodes = self.specs
        elif k in ("t", "task"):
            prefix = "T"
            nodes = self.tasks
        else:
            print("Error: next-id requires r|req, d|dec, s|spec, or t|task", file=sys.stderr)
            sys.exit(2)

        max_num = 0
        for n in nodes:
            match = re.search(r"\d+", n.id)
            if match:
                val = int(match.group(0))
                if val > max_num:
                    max_num = val

        return f"{prefix}{max_num + 1:02d}"

    def cmd_next_task(self):
        done_ids = {t.id for t in self.tasks if t.checked}
        ready = [
            t
            for t in self.tasks
            if not t.checked and (not t.blocked_by or all(dep in done_ids for dep in t.blocked_by))
        ]
        if not ready:
            print("NONE")
            return
        task = ready[0]

        # Print Essential Commands from AGENTS.md
        agents_file = self.root.parent / "AGENTS.md"
        if agents_file.is_file():
            in_cmd = False
            for line in agents_file.read_text(encoding="utf-8").splitlines():
                if line.startswith("## Essential Commands"):
                    in_cmd = True
                    print(line)
                    continue
                if in_cmd:
                    if line.startswith("## "):
                        break
                    print(line)
            print()

        # Print Task block
        self.print_block(task, show_location=True)
        print()

        # Print Spec parents
        seen_specs = set()
        seen_decs = set()
        seen_reqs = set()

        for spec in task.parents:
            if spec.id not in seen_specs:
                seen_specs.add(spec.id)
                self.print_block(spec, show_location=True)
                print()

                # Dec parents of this spec
                for dec in spec.parents:
                    if dec.kind == "DEC" and dec.id not in seen_decs:
                        seen_decs.add(dec.id)
                        self.print_block(dec, show_location=True)
                        print()
                        for req in dec.parents:
                            if req.kind == "REQ" and req.id not in seen_reqs:
                                seen_reqs.add(req.id)
                                self.print_block(req, show_location=True)
                                print()
                    elif dec.kind == "REQ" and dec.id not in seen_reqs:
                        seen_reqs.add(dec.id)
                        self.print_block(dec, show_location=True)
                        print()

    def cmd_next_id(self, kind_arg: str):
        print(self.next_id(kind_arg))

    def cmd_decide(
        self,
        req_raw: str,
        title: str,
        alternatives: str,
        consequences: str,
        verify: str,
    ):
        req_id = normalize_id(req_raw)
        req = self.nodes.get(req_id)
        if not req or req.kind != "REQ":
            print(f"Error: {req_raw} is not a known requirement", file=sys.stderr)
            sys.exit(1)

        did = self.next_id("d")
        path = self.root / "decisions.md"
        text = path.read_text(encoding="utf-8") if path.is_file() else "# Architectural Decisions\n"
        if not text.endswith("\n"):
            text += "\n"
        entry = (
            f"- [ ] {did} [{req_id}]: {title}\n"
            f"  - Alternatives: {alternatives}\n"
            f"  - Consequences: {consequences}\n"
            f"  - Verify: {verify}\n"
        )
        marker = "\n## Non-Goals"
        if marker in text:
            head, tail = text.split(marker, 1)
            text = head.rstrip() + "\n\n" + entry + marker + tail
        else:
            text = text.rstrip() + "\n\n" + entry
        path.write_text(text, encoding="utf-8")
        print(did)

    def cmd_tree(self, target_id: Optional[str] = None):
        """
        Renders the RDST tree data structure.
        Shows completion checkbox [x] / [ ] and completion ratios for parents.
        """
        if target_id:
            tid = normalize_id(target_id)
            node = self.nodes.get(tid)
            if not node:
                print(f"Error: Node {target_id} not found", file=sys.stderr)
                sys.exit(1)

            print(f"Artifact Trace Tree for {node.id}:")
            print("=" * (24 + len(node.id)))

            # Print Ancestors lineage
            def print_ancestor(n: Node, indent: str = ""):
                box = "[x]" if n.is_tree_completed() else "[ ]"
                ratio = f" ({sum(1 for c in n.children if c.is_tree_completed())}/{len(n.children)} complete)" if n.children else ""
                print(f"{indent}{box} {n.id}: {n.title}{ratio}")
                for p in n.parents:
                    print_ancestor(p, indent + "  ▲ ")

            if node.parents:
                print("Ancestors:")
                for p in node.parents:
                    print_ancestor(p, "  ")
                print("Target:")

            self._render_subtree(node, "", True)
            if node.blocked_by:
                print("Blocked by:")
                for b in node.blocked_by:
                    b_node = self.nodes.get(b)
                    b_status = "[x] (complete)" if (b_node and b_node.checked) else "[ ] (incomplete)"
                    print(f"  └── {b} {b_status}")
            return

        print("RDST Artifact Trace Tree:")
        print("=========================")
        # Roots are requirements
        for idx, req in enumerate(self.reqs):
            is_last = idx == len(self.reqs) - 1
            self._render_subtree(req, "", is_last)

    def _render_subtree(self, node: Node, prefix: str, is_last: bool):
        box = "[x]" if node.is_tree_completed() else "[ ]"
        connector = "└── " if is_last else "├── "

        # Annotations
        extras = []
        if node.children:
            completed_children = sum(1 for c in node.children if c.is_tree_completed())
            total_children = len(node.children)
            if completed_children == total_children:
                extras.append("all children complete")
            else:
                extras.append(f"{completed_children}/{total_children} complete")

        if node.blocked_by:
            extras.append(f"blocked-by: {', '.join(node.blocked_by)}")

        extra_str = f" ({'; '.join(extras)})" if extras else ""
        parent_tag = f" [{', '.join(node.parent_ids)}]" if node.parent_ids else ""

        if prefix == "" and node.kind == "REQ":
            # Top level root
            print(f"{box} {node.id}: {node.title}{extra_str}")
            child_prefix = "  "
        else:
            print(f"{prefix}{connector}{box} {node.id}{parent_tag}: {node.title}{extra_str}")
            child_prefix = prefix + ("    " if is_last else "│   ")

        for idx, child in enumerate(node.children):
            c_last = idx == len(node.children) - 1
            self._render_subtree(child, child_prefix, c_last)

    def cmd_trace(self, target_id: str):
        tid = normalize_id(target_id)
        node = self.nodes.get(tid)
        if not node:
            print(f"Error: Node {target_id} not found", file=sys.stderr)
            sys.exit(1)

        print(f"Trace for {node.id} ({node.kind}):")
        if node.file_path and node.line_number:
            print(f"  Location:       {node.file_path.name}:{node.line_number}")
        print(f"  Title:          {node.title}")
        print(f"  Status in file: {'[x] (checked)' if node.checked else '[ ] (open)'}")
        print(f"  Tree complete:  {'True' if node.is_tree_completed() else 'False'}")
        if node.verify_cmd:
            print(f"  Verify Command: {node.verify_cmd}")
        if node.blocked_by:
            print(f"  Blocked by:     {', '.join(node.blocked_by)}")

        parents_str = ", ".join(f"{p.id} ({p.kind} @ {p.file_path.name}:{p.line_number})" for p in node.parents) or "None (Root)"
        print(f"  Parents:        {parents_str}")

        children_str = ", ".join(f"{c.id} ({c.kind} @ {c.file_path.name}:{c.line_number})" for c in node.children) or "None (Leaf)"
        print(f"  Children:       {children_str}")

    def cmd_sync(self):
        """
        Settle parent checkboxes bottom-up according to child completion tree.
        "The parent is only completed when all the child is completed."
        """
        changes: List[Tuple[Node, bool, bool]] = []

        # Bottom-up order: SPECs -> DECs -> REQs
        tiers = [self.specs, self.decs, self.reqs]
        for tier in tiers:
            for node in tier:
                if not node.children:
                    # Leaf spec/decision without children remains untouched
                    continue

                all_children_done = node.is_tree_completed()
                if node.checked != all_children_done:
                    changes.append((node, node.checked, all_children_done))
                    node.checked = all_children_done

        if not changes:
            print("All parents already synchronized with child completion tree.")
            return

        # Apply changes in-place to files
        by_file: Dict[Path, List[Tuple[Node, bool]]] = {}
        for node, old_state, new_state in changes:
            by_file.setdefault(node.file_path, []).append((node, new_state))

        for file_path, updates in by_file.items():
            lines = file_path.read_text(encoding="utf-8").splitlines()
            line_updates = {n.line_number - 1: (n, s) for n, s in updates}

            for line_idx, (node, new_state) in line_updates.items():
                orig = lines[line_idx]
                target_char = "x" if new_state else " "
                # Replace checkbox
                updated = re.sub(
                    r"^([ \t]*-[ \t]*\[)[ xX](\][ \t]+" + re.escape(node.raw_id) + r"\b)",
                    r"\g<1>" + target_char + r"\g<2>",
                    orig,
                )
                lines[line_idx] = updated

            file_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        for node, old_state, new_state in changes:
            old_s = "[x]" if old_state else "[ ]"
            new_s = "[x]" if new_state else "[ ]"
            print(f"Synced {node.kind} {node.id}: {old_s} -> {new_s} (file: {node.file_path.name}:{node.line_number})")

    def architecture_sections(self) -> Set[str]:
        path = self.root / "architecture.md"
        if not path.is_file():
            return set()
        sections = set()
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^##[ \t]+(.+?)\s*$", line)
            if match:
                sections.add(match.group(1).strip())
        return sections

    def _question_ids(self) -> Set[str]:
        path = self.root / "questions.md"
        if not path.is_file():
            return set()
        ids = set()
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^[ \t]*-[ \t]*\[[ xX]\][ \t]+(Q\d+)\b", line)
            if match:
                ids.add(normalize_id(match.group(1)))
        return ids

    def cmd_verify_links(self):
        errors = 0
        warnings: List[str] = []

        # 0. Duplicate IDs and required verification commands.
        seen: Dict[str, Node] = {}
        for node in self.reqs + self.decs + self.specs + self.tasks:
            if node.id in seen:
                print(
                    f"Duplicate ID: {node.id} in {node.file_path.name}:{node.line_number} "
                    f"and {seen[node.id].file_path.name}:{seen[node.id].line_number}",
                    file=sys.stderr,
                )
                errors += 1
            else:
                seen[node.id] = node
            if node.kind in ("REQ", "SPEC", "TASK") and not node.verify_cmd:
                print(
                    f"Missing Verify: {node.id} ({node.file_path.name}:{node.line_number})",
                    file=sys.stderr,
                )
                errors += 1

        missing_arch_specs = [s for s in self.specs if not s.arch_section]
        if missing_arch_specs:
            print(
                f"Missing Arch: {len(missing_arch_specs)} specs must name an architecture section",
                file=sys.stderr,
            )
            errors += len(missing_arch_specs)
        missing_arch_decs = [d for d in self.decs if not d.arch_section]
        if missing_arch_decs:
            print(
                f"Missing Arch: {len(missing_arch_decs)} decisions must name an architecture section or none",
                file=sys.stderr,
            )
            errors += len(missing_arch_decs)

        ungrouped = {
            "requirements.md": sum(1 for n in self.reqs if not n.section),
            "decisions.md": sum(1 for n in self.decs if not n.section),
            "specs.md": sum(1 for n in self.specs if not n.section),
            f"{self.task_file}": sum(1 for n in self.tasks if not n.section),
        }
        for file_name, count in ungrouped.items():
            if count:
                warnings.append(f"{count} {file_name} items not grouped under H3")

        open_decs = [d for d in self.decs if not d.checked and not d.children]
        if open_decs:
            warnings.append(f"{len(open_decs)} open decisions remain; move unresolved choices to questions.md")

        arch_sections = self.architecture_sections()
        required_arch_sections = {
            "System Shape",
            "Module Seams",
            "Framework & Library Choices",
            "Data & Contracts",
            "Operations & Security",
        }
        if arch_sections:
            missing_sections = sorted(required_arch_sections - arch_sections)
            if missing_sections:
                warnings.append(
                    "architecture.md missing sections: " + ", ".join(missing_sections)
                )
        for node in self.specs + self.decs:
            if not node.arch_section:
                continue
            arch = node.arch_section.strip()
            if arch.lower() == "none":
                if node.kind == "SPEC":
                    print(
                        f"Invalid Arch: spec {node.id} must cite an architecture section "
                        f"({node.file_path.name}:{node.line_number})",
                        file=sys.stderr,
                    )
                    errors += 1
                continue
            if "architecture.md#" in arch or arch.startswith("architecture.md") or "#" in arch or "/" in arch:
                print(
                    f"Invalid Arch: {node.id} must name an architecture section, not a path "
                    f"({node.file_path.name}:{node.line_number}): {arch}",
                    file=sys.stderr,
                )
                errors += 1
            elif arch not in arch_sections:
                print(
                    f"Unknown Arch section: {node.id} cites {arch!r}, "
                    f"not an H2 in architecture.md ({node.file_path.name}:{node.line_number})",
                    file=sys.stderr,
                )
                errors += 1

        # 1a. Questions: grouping, duplicate IDs, and resolution links.
        q_ids: Set[str] = self._question_ids()
        seen_q: Set[str] = set()
        q_resolution: Dict[str, str] = {}
        questions_path = self.root / "questions.md"
        if questions_path.is_file():
            question_heading = ""
            current_q: Optional[str] = None
            checked = False
            resolution: Optional[str] = None
            has_origin = False

            def finish_question() -> None:
                nonlocal current_q, checked, resolution, has_origin
                if current_q is None:
                    return
                if not question_heading:
                    print(
                        f"Question {current_q} is not under an H3 source heading "
                        f"(questions.md:{current_q_line})",
                        file=sys.stderr,
                    )
                    errors += 1
                if checked and not resolution:
                    print(
                        f"Question {current_q} is resolved but has no Resolution: Dxx "
                        f"(questions.md:{current_q_line})",
                        file=sys.stderr,
                    )
                    errors += 1
                if not checked and resolution:
                    warnings.append(
                        f"Question {current_q} has Resolution {resolution} but is still open"
                    )
                if resolution:
                    q_resolution[current_q] = resolution
                    target = self.nodes.get(resolution)
                    if not target or target.kind != "DEC":
                        print(
                            f"Question {current_q} Resolution must name a decision: {resolution} "
                            f"(questions.md:{current_q_line})",
                            file=sys.stderr,
                        )
                        errors += 1
                if has_origin:
                    warnings.append(
                        f"Question {current_q} repeats source metadata with Origin; move it to the H3 heading"
                    )
                current_q = None
                checked = False
                resolution = None
                has_origin = False

            for q_line, q_text in enumerate(
                questions_path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                if q_text.startswith("### "):
                    finish_question()
                    question_heading = q_text[4:].strip()
                    continue
                if q_text.startswith("## ") or q_text.startswith("# "):
                    finish_question()
                    question_heading = ""
                    continue
                match = re.match(r"^[ \t]*-[ \t]*\[([ xX])\][ \t]+(Q\d+)\b", q_text)
                if match:
                    finish_question()
                    checked = match.group(1).lower() == "x"
                    current_q = normalize_id(match.group(2))
                    current_q_line = q_line
                    if current_q in seen_q:
                        print(
                            f"Duplicate question ID: {current_q} (questions.md:{q_line})",
                            file=sys.stderr,
                        )
                        errors += 1
                    seen_q.add(current_q)
                    continue
                if current_q is None:
                    continue
                if re.match(r"^[ \t]*-[ \t]*Origin:", q_text, re.IGNORECASE):
                    has_origin = True
                resolution_match = re.match(
                    r"^[ \t]*-[ \t]*Resolution:[ \t]*(Q?\d+|[D|S|T]\d+)\b",
                    q_text,
                    re.IGNORECASE,
                )
                if resolution_match:
                    resolution = normalize_id(resolution_match.group(1))
                blocks_match = re.match(
                    r"^[ \t]*-[ \t]*Blocks:[ \t]*(.+)$", q_text, re.IGNORECASE
                )
                if blocks_match:
                    for blocked in re.split(r"[, \t]+", blocks_match.group(1).strip()):
                        blocked = normalize_id(blocked)
                        if not blocked or blocked.lower() == "none":
                            continue
                        if blocked not in self.nodes and blocked not in q_ids:
                            print(
                                f"Question {current_q} Blocks unknown ID: {blocked} "
                                f"(questions.md:{q_line})",
                                file=sys.stderr,
                            )
                            errors += 1
            finish_question()

        # 1b. Reference existence check
        for dec in self.decs:
            for pid in dec.parent_ids:
                if pid not in self.nodes:
                    print(f"Missing REQ ID: {pid} (referenced in decisions.md line {dec.line_number})", file=sys.stderr)
                    errors += 1

        for spec in self.specs:
            for pid in spec.parent_ids:
                if pid not in self.nodes:
                    print(f"Missing ID: {pid} (referenced in specs.md line {spec.line_number})", file=sys.stderr)
                    errors += 1

        for task in self.tasks:
            for pid in task.parent_ids:
                if pid not in self.nodes:
                    print(f"Missing ID: {pid} (referenced in {task.file_path.name} line {task.line_number})", file=sys.stderr)
                    errors += 1
            for b in task.blocked_by:
                if b not in self.nodes:
                    print(f"Missing blocked-by TASK ID: {b} (referenced in {task.file_path.name} line {task.line_number})", file=sys.stderr)
                    errors += 1

        # 2. Invariant check: Parent is ONLY completed when all children are completed!
        for node in self.nodes.values():
            if node.children:
                if node.checked and not node.is_tree_completed():
                    open_children = [c.id for c in node.children if not c.is_tree_completed()]
                    print(
                        f"Invariant violation: Parent {node.kind} {node.id} is marked complete [x] "
                        f"in {node.file_path.name}:{node.line_number}, but child items are incomplete: {', '.join(open_children)}",
                        file=sys.stderr,
                    )
                    errors += 1

        # 3. Line syntax check for specs.md
        specs_path = self.root / "specs.md"
        if specs_path.is_file():
            re_spec_allowed = re.compile(
                r"^([ \t]*|#{1,6}[ \t]+.*|[ \t]*-[ \t]*\[[xX ]\][ \t]+(?:SPEC-|S)\d+(?:[ \t]+\[[^]]+\])+:[ \t]+.+|[ \t][ \t]+.*)$"
            )
            for lno, line in enumerate(specs_path.read_text(encoding="utf-8").splitlines(), start=1):
                if not re_spec_allowed.match(line):
                    print(f"Invalid specs.md line {lno}: {line}", file=sys.stderr)
                    errors += 1

        # 4. Kind and cycle checks
        for dec in self.decs:
            for pid in dec.parent_ids:
                if pid in self.nodes and self.nodes[pid].kind != "REQ":
                    print(
                        f"Invalid decision parent: {pid} is {self.nodes[pid].kind}, not REQ "
                        f"(decisions.md line {dec.line_number})",
                        file=sys.stderr,
                    )
                    errors += 1

        for spec in self.specs:
            kinds = {self.nodes[pid].kind for pid in spec.parent_ids if pid in self.nodes}
            if "REQ" not in kinds or "DEC" not in kinds:
                print(
                    f"Invalid spec parents: need REQ and DEC, got {', '.join(sorted(kinds)) or 'none'} "
                    f"(specs.md line {spec.line_number})",
                    file=sys.stderr,
                )
                errors += 1

        for task in self.tasks:
            for pid in task.parent_ids:
                if pid in self.nodes and self.nodes[pid].kind != "SPEC":
                    print(
                        f"Invalid task parent: {pid} is {self.nodes[pid].kind}, not SPEC "
                        f"({task.file_path.name} line {task.line_number})",
                        file=sys.stderr,
                    )
                    errors += 1

        for dec in self.decs:
            for qid in dec.resolves:
                if qid not in q_ids:
                    print(
                        f"Decision {dec.id} Resolves unknown question: {qid} "
                        f"(decisions.md:{dec.line_number})",
                        file=sys.stderr,
                    )
                    errors += 1
                elif q_resolution.get(qid) != dec.id:
                    warnings.append(
                        f"Decision {dec.id} cites Resolves: {qid}, but the question does not cite it back"
                    )

        adjacency = {t.id: [b for b in t.blocked_by if b in self.nodes] for t in self.tasks}
        state: Dict[str, int] = {}

        def visit(node_id: str, stack: List[str]) -> bool:
            mark = state.get(node_id, 0)
            if mark == 1:
                if node_id in stack:
                    cycle = stack[stack.index(node_id) :] + [node_id]
                    print(f"Dependency cycle: {' -> '.join(cycle)}", file=sys.stderr)
                    return True
                return False
            if mark == 2:
                return False
            state[node_id] = 1
            for blocker in adjacency.get(node_id, []):
                if visit(blocker, stack + [node_id]):
                    return True
            state[node_id] = 2
            return False

        for task in self.tasks:
            if visit(task.id, []):
                errors += 1

        if warnings:
            print("Warnings:", file=sys.stderr)
            for warning in warnings:
                print(f"  - {warning}", file=sys.stderr)

        if errors > 0:
            print(f"verify-links failed with {errors} errors.", file=sys.stderr)
            sys.exit(1)

        print("OK")

    def reformat_file(self, path: Path) -> int:
        if not path.is_file():
            return 0
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        new_lines = []
        in_fence = False
        reformatted_count = 0
        pattern = re.compile(r"^(\s*-\s*\[[ xX]\].*?)\s*\|\s*Verify:\s*(.*)$")

        for line in lines:
            stripped = line.strip()
            if stripped.startswith("```"):
                in_fence = not in_fence
                new_lines.append(line)
                continue

            if in_fence or stripped.startswith("|"):
                new_lines.append(line)
                continue

            m = pattern.match(line)
            if m:
                item_header = m.group(1).rstrip()
                verify_cmd = m.group(2).strip()
                indent_match = re.match(r"^(\s*)", line)
                base_indent = indent_match.group(1) if indent_match else ""
                sub_indent = base_indent + "  "

                new_lines.append(item_header)
                new_lines.append(f"{sub_indent}- Verify: {verify_cmd}")
                reformatted_count += 1
            else:
                new_lines.append(line)

        if reformatted_count > 0:
            path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        return reformatted_count

    def cmd_reformat(self, targets: List[str]):
        if not targets:
            target_paths = list(self.root.glob("*.md"))
        else:
            target_paths = []
            for t in targets:
                p = Path(t)
                if p.is_dir():
                    target_paths.extend(p.rglob("*.md"))
                elif p.is_file():
                    target_paths.append(p)

        total_files = 0
        total_items = 0
        for p in sorted(set(target_paths)):
            count = self.reformat_file(p)
            if count > 0:
                print(f"Reformatted {count} items in {p}")
                total_files += 1
                total_items += count

        print(f"Total: reformatted {total_items} items across {total_files} file(s).")


def print_usage():
    print(
        "Usage: artifacts.sh <status|unconverted-reqs|unconverted-decs|unconverted-specs|next-task|frontier|next-id <r|d|s|t>|decide <Rxx> <title> --alternatives ... --consequences ... --verify ...|tree [ID]|trace <ID>|sync|check|verify-links|reformat [targets...]>",
        file=sys.stderr,
    )
    sys.exit(2)


def main():
    if len(sys.argv) < 2:
        print_usage()

    cmd = sys.argv[1].lower()
    repo = ArtifactsRepository()

    if cmd == "status":
        repo.cmd_status()
    elif cmd == "unconverted-reqs":
        repo.cmd_unconverted_reqs()
    elif cmd == "unconverted-decs":
        repo.cmd_unconverted_decs()
    elif cmd == "unconverted-specs":
        repo.cmd_unconverted_specs()
    elif cmd == "next-task":
        repo.cmd_next_task()
    elif cmd == "frontier":
        repo.cmd_frontier()
    elif cmd == "decide":
        parser = argparse.ArgumentParser(prog="artifacts.sh decide")
        parser.add_argument("req")
        parser.add_argument("title")
        parser.add_argument("--alternatives", required=True)
        parser.add_argument("--consequences", required=True)
        parser.add_argument("--verify", required=True)
        args = parser.parse_args(sys.argv[2:])
        repo.cmd_decide(
            args.req,
            args.title,
            args.alternatives,
            args.consequences,
            args.verify,
        )
    elif cmd == "next-id":
        if len(sys.argv) < 3:
            print("Error: next-id requires r|req, d|dec, s|spec, or t|task", file=sys.stderr)
            sys.exit(2)
        repo.cmd_next_id(sys.argv[2])
    elif cmd == "tree":
        target = sys.argv[2] if len(sys.argv) > 2 else None
        repo.cmd_tree(target)
    elif cmd == "trace":
        if len(sys.argv) < 3:
            print("Error: ID required for trace subcommand", file=sys.stderr)
            sys.exit(2)
        repo.cmd_trace(sys.argv[2])
    elif cmd in ("sync", "settle"):
        repo.cmd_sync()
    elif cmd in ("check", "verify-links"):
        repo.cmd_verify_links()
    elif cmd == "reformat":
        repo.cmd_reformat(sys.argv[2:])
    else:
        print(f"Unknown subcommand: {cmd}", file=sys.stderr)
        print_usage()


if __name__ == "__main__":
    main()
