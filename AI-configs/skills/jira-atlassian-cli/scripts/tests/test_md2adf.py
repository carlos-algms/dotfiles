"""Tests for md2adf.py. Run: python3 -m unittest discover -s <this dir>"""

import io
import json
import os
import sys
import tempfile
import time
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import md2adf  # noqa: E402

CONFIG = """\
# comment line
my_team: team-a
my_email: me@example.com

teams:
  team-a:
    name: Team A
    project_key: AAA
    team_field: customfield_1
    team_id: "uuid-a"
    sprint_field: customfield_2
    refinement_sprint_id: 11  # inline comment
    active_sprint_board_id: 5
  team-b:
    project_key: BBB
    team_field: customfield_1
    team_id: uuid-b
    sprint_field: customfield_2
    refinement_sprint_id: 22
"""


def t(text, *marks):
    node = {"type": "text", "text": text}
    if marks:
        node["marks"] = [m if isinstance(m, dict) else {"type": m} for m in marks]
    return node


def link(href):
    return {"type": "link", "attrs": {"href": href}}


def para(*content):
    return {"type": "paragraph", "content": list(content)}


def blocks(md):
    return md2adf.markdown_to_adf(md)["content"]


def inline(md):
    (p,) = blocks(md)
    assert p["type"] == "paragraph", p
    return p["content"]


def local_ids(node):
    ids = []
    if isinstance(node, dict):
        if "localId" in node.get("attrs", {}):
            ids.append(node["attrs"]["localId"])
        for v in node.values():
            ids += local_ids(v)
    elif isinstance(node, list):
        for v in node:
            ids += local_ids(v)
    return ids


class BlockTests(unittest.TestCase):
    def test_heading_closing_hashes_and_spaces(self):
        cases = {"# a ##": "a", "# a   ": "a", "# a#": "a#", "# #": "#", "#  a  #  ": "a"}
        for md, want in cases.items():
            with self.subTest(md=md):
                self.assertEqual(blocks(md)[0]["content"], [t(want)])

    def test_headings_and_envelope(self):
        doc = md2adf.markdown_to_adf("# One\n\n###### Six")
        self.assertEqual((doc["type"], doc["version"]), ("doc", 1))
        self.assertEqual(
            doc["content"],
            [
                {"type": "heading", "attrs": {"level": 1}, "content": [t("One")]},
                {"type": "heading", "attrs": {"level": 6}, "content": [t("Six")]},
            ],
        )

    def test_soft_break_joins_with_space(self):
        self.assertEqual(inline("a\nb"), [t("a b")])

    def test_hard_break_two_spaces_and_backslash(self):
        hb = {"type": "hardBreak"}
        self.assertEqual(inline("a  \nb"), [t("a"), hb, t("b")])
        self.assertEqual(inline("a\\\nb"), [t("a"), hb, t("b")])

    def test_rule(self):
        self.assertEqual(blocks("a\n\n---\n\nb")[1], {"type": "rule"})

    def test_blockquote(self):
        self.assertEqual(
            blocks("> quoted\n> more"),
            [{"type": "blockquote", "content": [para(t("quoted more"))]}],
        )

    def test_panel(self):
        got = blocks(":::panel warning\nCareful\n:::")
        self.assertEqual(
            got,
            [
                {
                    "type": "panel",
                    "attrs": {"panelType": "warning"},
                    "content": [para(t("Careful"))],
                }
            ],
        )

    def test_expand_holds_blocks(self):
        got = blocks(":::expand More detail\n- a\n- b\n:::")
        self.assertEqual(got[0]["type"], "expand")
        self.assertEqual(got[0]["attrs"], {"title": "More detail"})
        self.assertEqual(got[0]["content"][0]["type"], "bulletList")


class InlineTests(unittest.TestCase):
    def test_bold_italic_strike_code(self):
        self.assertEqual(
            inline("**b** *i* _j_ ~~s~~ `c`"),
            [
                t("b", "strong"),
                t(" "),
                t("i", "em"),
                t(" "),
                t("j", "em"),
                t(" "),
                t("s", "strike"),
                t(" "),
                t("c", "code"),
            ],
        )

    def test_nested_marks(self):
        self.assertEqual(
            inline("**bold *both***"),
            [t("bold ", "strong"), t("both", "strong", "em")],
        )

    def test_snake_case_is_not_italic(self):
        self.assertEqual(inline("a_b_c and snake_case_name"), [t("a_b_c and snake_case_name")])

    def test_code_inside_bold_keeps_only_code(self):
        self.assertEqual(
            inline("**bold `code`**"), [t("bold ", "strong"), t("code", "code")]
        )

    def test_double_backtick_code_with_backtick(self):
        self.assertEqual(inline("``a`b``"), [t("a`b", "code")])

    def test_unmatched_backtick_is_literal(self):
        self.assertEqual(inline("a ` b"), [t("a ` b")])

    def test_escapes(self):
        self.assertEqual(inline(r"\*not bold\* \[x\]"), [t("*not bold* [x]")])

    def test_link(self):
        self.assertEqual(
            inline("[a](https://x.com)"), [t("a", link("https://x.com"))]
        )

    def test_link_url_with_parens(self):
        self.assertEqual(
            inline("[a](https://x.com/a_(b))"),
            [t("a", link("https://x.com/a_(b)"))],
        )

    def test_link_text_with_marks(self):
        self.assertEqual(
            inline("[**b** `c`](https://x.com)"),
            [
                t("b", "strong", link("https://x.com")),
                t(" ", link("https://x.com")),
                t("c", "code", link("https://x.com")),
            ],
        )

    def test_autolink_becomes_inline_card(self):
        url = "https://p.atlassian.net/browse/EXP-1"
        self.assertEqual(
            inline(f"see <{url}> now"),
            [t("see "), {"type": "inlineCard", "attrs": {"url": url}}, t(" now")],
        )

    def test_literal_text_passthrough(self):
        for md in ("go https://x.com now", "a < b > c", "[a][b]", "a <b>x</b> c"):
            with self.subTest(md=md):
                self.assertEqual(inline(md), [t(md)])


class ListTests(unittest.TestCase):
    def test_bullet_markers(self):
        for marker in "-*+":
            with self.subTest(marker=marker):
                (lst,) = blocks(f"{marker} a\n{marker} b")
                self.assertEqual(lst["type"], "bulletList")
                self.assertEqual(len(lst["content"]), 2)

    def test_ordered(self):
        (lst,) = blocks("1. a\n2. b")
        self.assertEqual(
            lst,
            {
                "type": "orderedList",
                "content": [
                    {"type": "listItem", "content": [para(t("a"))]},
                    {"type": "listItem", "content": [para(t("b"))]},
                ],
            },
        )

    def test_nested_mixed(self):
        (lst,) = blocks("- a\n  1. x\n  2. y\n- b")
        first = lst["content"][0]["content"]
        self.assertEqual(first[0], para(t("a")))
        self.assertEqual(first[1]["type"], "orderedList")
        self.assertEqual(len(first[1]["content"]), 2)

    def test_deep_nesting(self):
        (lst,) = blocks("- a\n  - b\n    - c")
        inner = lst["content"][0]["content"][1]["content"][0]["content"][1]
        self.assertEqual(inner["content"][0]["content"], [para(t("c"))])

    def test_item_with_second_paragraph_and_code(self):
        (lst,) = blocks("- a\n\n  more\n\n  ```js\n  x\n  ```")
        kinds = [n["type"] for n in lst["content"][0]["content"]]
        self.assertEqual(kinds, ["paragraph", "paragraph", "codeBlock"])

    def test_continuation_line_joins(self):
        (lst,) = blocks("- a\n  b")
        self.assertEqual(lst["content"][0]["content"], [para(t("a b"))])
        (lst,) = blocks("- [ ] a\n  b")
        self.assertEqual(lst["content"][0]["content"], [t("a b")])

    def test_kind_change_splits_lists(self):
        got = blocks("- a\n1. b")
        self.assertEqual([n["type"] for n in got], ["bulletList", "orderedList"])


class TaskTests(unittest.TestCase):
    def test_open_and_done(self):
        (lst,) = blocks("- [ ] open\n- [x] done\n- [X] done too")
        self.assertEqual(lst["type"], "taskList")
        states = [i["attrs"]["state"] for i in lst["content"]]
        self.assertEqual(states, ["TODO", "DONE", "DONE"])

    def test_task_item_content_is_bare_inline(self):
        (lst,) = blocks("- [ ] **b** and `c`")
        self.assertEqual(
            lst["content"][0]["content"], [t("b", "strong"), t(" and "), t("c", "code")]
        )

    def test_tasks_split_from_bullets(self):
        got = blocks("- [ ] a\n- plain")
        self.assertEqual([n["type"] for n in got], ["taskList", "bulletList"])

    def test_nested_checklist_is_sibling_task_list(self):
        (lst,) = blocks("- [ ] a\n  - [x] b\n- [ ] c")
        kinds = [n["type"] for n in lst["content"]]
        self.assertEqual(kinds, ["taskItem", "taskList", "taskItem"])
        nested = lst["content"][1]
        self.assertEqual(nested["content"][0]["attrs"]["state"], "DONE")
        self.assertEqual(nested["content"][0]["content"], [t("b")])
        self.assertEqual(lst["content"][0]["content"], [t("a")])

    def test_deeply_nested_checklist(self):
        (lst,) = blocks("- [ ] a\n  - [ ] b\n    - [ ] c")
        inner = lst["content"][1]["content"][1]
        self.assertEqual(inner["type"], "taskList")
        self.assertEqual(inner["content"][0]["content"], [t("c")])

    def test_local_ids_unique_and_deterministic(self):
        md = "- [ ] same\n- [ ] same\n  - [ ] b\n  - [ ] c\n\n- [ ] same\n"
        ids = local_ids(md2adf.markdown_to_adf(md))
        self.assertEqual(len(ids), 7)
        self.assertEqual(len(set(ids)), 7)
        self.assertEqual(ids, local_ids(md2adf.markdown_to_adf(md)))


class CodeTests(unittest.TestCase):
    def test_fenced_with_language(self):
        self.assertEqual(
            blocks("```ts\nconst a = 1;\n\nb();\n```"),
            [
                {
                    "type": "codeBlock",
                    "attrs": {"language": "ts"},
                    "content": [t("const a = 1;\n\nb();")],
                }
            ],
        )

    def test_markdown_inside_fence_is_untouched(self):
        (node,) = blocks("```\n# not heading\n- [ ] not task\n| a | b |\n```")
        self.assertEqual(node["content"][0]["text"], "# not heading\n- [ ] not task\n| a | b |")

    def test_longer_fence_holds_shorter(self):
        (node,) = blocks("````\n```\ninner\n```\n````")
        self.assertEqual(node["content"][0]["text"], "```\ninner\n```")

    def test_fence_variants(self):
        cases = [
            ("```\nx\n```", {"type": "codeBlock", "content": [t("x")]}),
            ("```\n```", {"type": "codeBlock"}),
            ("~~~py\nx\n~~~", {"type": "codeBlock", "attrs": {"language": "py"}, "content": [t("x")]}),
        ]
        for md, want in cases:
            with self.subTest(md=md):
                self.assertEqual(blocks(md), [want])


class TableTests(unittest.TestCase):
    def cell(self, kind, *content):
        return {"type": kind, "content": [para(*content)]}

    def test_basic_table(self):
        (tbl,) = blocks("| A | B |\n|---|:-:|\n| 1 | `2` |\n| 3 | **4** |")
        self.assertEqual(tbl["type"], "table")
        self.assertEqual(tbl["attrs"], {"isNumberColumnEnabled": False, "layout": "default"})
        header, row1, row2 = tbl["content"]
        self.assertEqual(
            header,
            {
                "type": "tableRow",
                "content": [self.cell("tableHeader", t("A")), self.cell("tableHeader", t("B"))],
            },
        )
        self.assertEqual(
            row1["content"],
            [self.cell("tableCell", t("1")), self.cell("tableCell", t("2", "code"))],
        )
        self.assertEqual(row2["content"][1], self.cell("tableCell", t("4", "strong")))

    def test_without_outer_pipes(self):
        (tbl,) = blocks("A | B\n--|--\n1 | 2")
        self.assertEqual(len(tbl["content"]), 2)

    def test_escaped_pipe_stays_in_cell(self):
        (tbl,) = blocks("| A |\n|---|\n| x \\| y |")
        self.assertEqual(tbl["content"][1]["content"][0], self.cell("tableCell", t("x | y")))

    def test_short_row_padded_with_empty_cell(self):
        (tbl,) = blocks("| A | B |\n|---|---|\n| 1 |")
        self.assertEqual(
            tbl["content"][1]["content"][1],
            {"type": "tableCell", "content": [{"type": "paragraph"}]},
        )

    def test_pipes_without_delimiter_row_are_paragraph(self):
        (node,) = blocks("a | b\nc | d")
        self.assertEqual(node["type"], "paragraph")

    def test_link_in_cell(self):
        (tbl,) = blocks("| A |\n|---|\n| <https://x.com/y> |")
        card = tbl["content"][1]["content"][0]["content"][0]["content"][0]
        self.assertEqual(card, {"type": "inlineCard", "attrs": {"url": "https://x.com/y"}})

    def test_table_ends_at_blank_line(self):
        got = blocks("| A |\n|---|\n| 1 |\n\nafter")
        self.assertEqual([n["type"] for n in got], ["table", "paragraph"])


class UnsupportedTests(unittest.TestCase):
    CASES = [
        # (markdown, line the error points at)
        ("ok\n\n<div>x</div>", 3),
        ("![alt](https://x.com/a.png)", 1),
        ("Title\n=====", 2),
        ("Title\n-----", 2),
        ("ok\n\n    code", 3),
        ("  \n\n", 1),
        (":::panel info\nno close", 1),
        (":::panel bogus\nx\n:::", 1),
        (":::weird\nx\n:::", 1),
        (":::expand E\n:::panel info\nx\n:::\n:::", 2),
        ("[a](/relative)", 1),
        ("```\nx", 1),
        ("| A |\n|---|\n| 1 | 2 |", 3),
        ("- [ ] a\n  - plain", 1),
        ("- [ ] a\n\n  ```\n  x\n  ```", 1),
        ("- a\n  - [ ] b", 1),
        # structure ADF cannot hold: reported with a line, not silently dropped
        ("> # h", 1),
        ("ok\n\n- a\n  > q", 3),
        ("- # h", 1),
        ("- ", 1),
        (">", 1),
        (":::panel info\n:::", 1),
        (":::expand x\n:::", 1),
        ("[](https://x.com)", 1),
        ("- | a |\n  |---|\n  | 1 |", 1),
        ("- a\n  | a |\n  |---|\n  | 1 |", 2),
    ]

    def test_errors_carry_the_line(self):
        for md, line in self.CASES:
            with self.subTest(md=md):
                with self.assertRaises(md2adf.UnsupportedMarkdown) as ctx:
                    md2adf.markdown_to_adf(md)
                self.assertEqual(ctx.exception.line, line, ctx.exception)
                self.assertTrue(str(ctx.exception).startswith(f"line {line}: "))


class InputNormalisationTests(unittest.TestCase):
    def test_bom_and_lone_cr(self):
        self.assertEqual(blocks("\ufeff# h"), blocks("# h"))
        self.assertEqual(blocks("# a\r\r- b\r"), blocks("# a\n\n- b\n"))


class PerformanceTests(unittest.TestCase):
    def test_long_whitespace_runs_stay_fast(self):
        for md in ("# h" + " " * 30000 + "x", "| A |\n|---" + " " * 30000 + "-|\n| 1 |"):
            with self.subTest(md=md[:9]):
                start = time.perf_counter()
                md2adf.markdown_to_adf(md)
                self.assertLess(time.perf_counter() - start, 1.0)

    def test_unclosed_delimiters_stay_fast(self):
        for md in ("*a " * 2000, "a * b *c\n" * 2000, "[a " * 2000, "_a " * 2000):
            with self.subTest(md=md[:9]):
                start = time.perf_counter()
                md2adf.markdown_to_adf(md)
                self.assertLess(time.perf_counter() - start, 1.0)


class ConfigTests(unittest.TestCase):
    def write(self, text):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        path = os.path.join(tmp.name, "jira.yaml")
        with open(path, "w") as fh:
            fh.write(text)
        return path

    def test_parses_nested_scalars_comments_quotes(self):
        cfg = md2adf.load_config(self.write(CONFIG))
        self.assertEqual(cfg["my_team"], "team-a")
        self.assertEqual(cfg["my_email"], "me@example.com")
        self.assertEqual(cfg["teams"]["team-a"]["team_id"], "uuid-a")
        self.assertEqual(cfg["teams"]["team-a"]["refinement_sprint_id"], 11)
        self.assertEqual(cfg["teams"]["team-b"]["project_key"], "BBB")

    def test_comment_after_key_and_quote_escapes(self):
        cfg = md2adf.load_config(
            self.write("teams:  # all teams\n  a:\n    k: 'it''s'  # c\n    j: \"a\\\"b\\\\c\"\n")
        )
        self.assertEqual(cfg, {"teams": {"a": {"k": "it's", "j": 'a"b\\c'}}})

    def test_unsupported_yaml_errors(self):
        for text in ("teams:\n  - a\n  - b\n", "x: [1, 2]\n", "x: {a: 1}\n", "x: 'open\n"):
            with self.subTest(text=text), self.assertRaises(md2adf.UsageError):
                md2adf.load_config(self.write(text))

    def test_missing_file_errors(self):
        with self.assertRaises(md2adf.UsageError):
            md2adf.load_config("/nonexistent/jira.yaml")


class CliTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.dir = tmp.name
        self.cfg = os.path.join(self.dir, "jira.yaml")
        with open(self.cfg, "w") as fh:
            fh.write(CONFIG)

    def run_cli(self, args, stdin="hello"):
        out, err = io.StringIO(), io.StringIO()
        code = md2adf.main(args, io.StringIO(stdin), out, err)
        return code, out.getvalue(), err.getvalue()

    def create(self, *extra, stdin="hello"):
        code, out, err = self.run_cli(
            ["--format", "acli-create", "--config", self.cfg, "--summary", "S", *extra], stdin
        )
        self.assertEqual(code, 0, err)
        return json.loads(out)

    def test_default_format_is_bare_adf_and_deterministic(self):
        code, out, _ = self.run_cli([])
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(out), md2adf.markdown_to_adf("hello"))
        self.assertEqual(self.run_cli([], "- [ ] a\n")[1], self.run_cli([], "- [ ] a\n")[1])

    def test_output_is_ascii_json(self):
        out = self.run_cli([], "caf\u00e9 \U0001f600")[1]
        self.assertTrue(out.isascii())
        self.assertEqual(json.loads(out)["content"][0]["content"][0]["text"], "caf\u00e9 \U0001f600")

    def test_create_payload_defaults(self):
        got = self.create()
        self.assertEqual(
            got,
            {
                "projectKey": "AAA",
                "type": "Task",
                "summary": "S",
                "additionalAttributes": {"customfield_1": "uuid-a", "customfield_2": 11},
                "description": md2adf.markdown_to_adf("hello"),
            },
        )

    def test_create_all_options(self):
        got = self.create(
            "--parent", "AAA-9", "--type", "Bug", "--label", "x", "--label", "y",
            "--assignee", "bob@example.com", "--sprint", "4242",
        )
        self.assertEqual(got["parentIssueId"], "AAA-9")
        self.assertEqual(got["type"], "Bug")
        self.assertEqual(got["labels"], ["x", "y"])
        self.assertEqual(got["assignee"], "bob@example.com")
        self.assertEqual(got["additionalAttributes"]["customfield_2"], 4242)

    def test_assignee_me_reads_my_email(self):
        self.assertEqual(self.create("--assignee", "me")["assignee"], "me@example.com")

    def test_team_selection(self):
        got = self.create("--team", "team-b")
        self.assertEqual(got["projectKey"], "BBB")
        self.assertEqual(got["additionalAttributes"]["customfield_2"], 22)
        self.assertEqual(got["additionalAttributes"]["customfield_1"], "uuid-b")

    def test_edit_payload(self):
        code, out, err = self.run_cli(
            [
                "--format", "acli-edit", "--issues", "AAA-1,AAA-2", "--summary", "New",
                "--assignee", "me", "--config", self.cfg, "--label-add", "a", "--label-remove", "b",
            ]
        )
        self.assertEqual(code, 0, err)
        self.assertEqual(
            json.loads(out),
            {
                "issues": ["AAA-1", "AAA-2"],
                "summary": "New",
                "assignee": "me@example.com",
                "labelsToAdd": ["a"],
                "labelsToRemove": ["b"],
                "description": md2adf.markdown_to_adf("hello"),
            },
        )

    def test_edit_minimal_has_only_issues_and_description(self):
        code, out, _ = self.run_cli(["--format", "acli-edit", "--issues", "AAA-1"])
        self.assertEqual(code, 0)
        self.assertEqual(set(json.loads(out)), {"issues", "description"})

    def test_read_from_file(self):
        md = os.path.join(self.dir, "in.md")
        with open(md, "w") as fh:
            fh.write("# From file\n")
        code, out, _ = self.run_cli([md], stdin="ignored")
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(out)["content"][0]["type"], "heading")

    def test_failures_exit_2_with_message_and_no_output(self):
        create = ["--format", "acli-create", "--config", self.cfg, "--summary", "S"]
        bad_utf8 = os.path.join(self.dir, "bad.md")
        with open(bad_utf8, "wb") as fh:
            fh.write(b"\xff\xfe")
        cases = [
            # (args, stdin, config text or None, expected stderr substring)
            (create + ["--assignee", "@me"], "x", None, "@me"),
            (create + ["--team", "nope"], "x", None, "nope"),
            (create + ["--sprint", "soon"], "x", None, "--sprint"),
            (create + ["--sprint", "\u00b2"], "x", None, "--sprint"),
            (create + ["--assignee", ""], "x", None, "--assignee"),
            (create + ["--parent", ""], "x", None, "--parent"),
            (["--format", "acli-edit", "--issues", ","], "x", None, "--issues"),
            (["--format", "acli-create", "--config", self.cfg], "x", None, "--summary"),
            (["--format", "acli-edit"], "x", None, "--issues"),
            (["--summary", "S"], "x", None, "does not apply"),
            (create + ["--assignee", "me"], "x", CONFIG.replace("my_email: me@example.com\n", ""), "my_email"),
            (create, "x", CONFIG.replace("project_key: AAA", "project_key:"), "project_key"),
            (create, "x", CONFIG.replace("team_field: customfield_1", "team_field:", 1), "team_field"),
            (create, "x", "my_team: a\nteams: x\n", "teams"),
            (create, "x", "my_team: a\nteams:  # none\n", "teams"),
            ([], "![x](https://y.z)", None, "line 1"),
            ([], ">" * 2000, None, "nested"),
            ([bad_utf8], "x", None, "utf-8"),
        ]
        for args, stdin, cfg_text, want in cases:
            with self.subTest(args=args[-2:], want=want):
                if cfg_text is not None:
                    with open(self.cfg, "w") as fh:
                        fh.write(cfg_text)
                code, out, err = self.run_cli(args, stdin)
                self.assertEqual(code, 2, err)
                self.assertEqual(out, "")
                self.assertIn(want, err)
                self.assertNotIn("Traceback", err)

    def test_output_file_written_idempotent_stdout_empty(self):
        dest = os.path.join(self.dir, "out.json")
        code, out, _ = self.run_cli(["-o", dest], "- [ ] a")
        self.assertEqual((code, out), (0, ""))
        with open(dest) as fh:
            first = fh.read()
        self.assertEqual(json.loads(first), md2adf.markdown_to_adf("- [ ] a"))
        self.run_cli(["-o", dest], "- [ ] a")
        with open(dest) as fh:
            self.assertEqual(fh.read(), first)
        self.assertEqual(sorted(os.listdir(self.dir)), ["jira.yaml", "out.json"])

    def test_output_keeps_mode_and_follows_symlink(self):
        real = os.path.join(self.dir, "real.json")
        with open(real, "w") as fh:
            fh.write("old")
        os.chmod(real, 0o644)
        link_path = os.path.join(self.dir, "link.json")
        os.symlink(real, link_path)
        self.assertEqual(self.run_cli(["-o", link_path])[0], 0)
        self.assertTrue(os.path.islink(link_path))
        self.assertEqual(os.stat(real).st_mode & 0o777, 0o644)
        with open(real) as fh:
            self.assertEqual(json.load(fh), md2adf.markdown_to_adf("hello"))

    def test_failure_leaves_existing_output_untouched(self):
        dest = os.path.join(self.dir, "out.json")
        with open(dest, "w") as fh:
            fh.write("keep")
        code, _, _ = self.run_cli(["-o", dest], "![x](https://y.z)")
        self.assertEqual(code, 2)
        with open(dest) as fh:
            self.assertEqual(fh.read(), "keep")
        self.assertEqual(sorted(os.listdir(self.dir)), ["jira.yaml", "out.json"])


if __name__ == "__main__":
    unittest.main()
