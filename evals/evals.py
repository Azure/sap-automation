#!/usr/bin/env python3

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""Evaluate SDAF skill invocation through the official GitHub Copilot SDK."""

from __future__ import annotations
import argparse
import asyncio
import hashlib
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence
from copilot import (
    CopilotClient,
    ModelCapabilitiesOverride,
    ModelLimitsOverride,
    RuntimeConnection,
    SessionEvent,
    SessionEventType,
    ToolSet,
)
from copilot.session_events import (
    AssistantMessageData,
    AssistantUsageData,
    SessionErrorData,
    SessionIdleData,
    SessionSkillsLoadedData,
    SkillInvokedData,
    SkillInvokedTrigger,
    SkillsLoadedSkill,
)

CASE_ID_PATTERN = re.compile(r"\A[a-z0-9]+(?:-[a-z0-9]+)*\Z")
SKILL_REFERENCE_PATTERN = re.compile(r"\bsdaf-[a-z0-9]+(?:-[a-z0-9]+)*\b")
ASSERTION_COUNT = 5
DEFAULT_AI_CREDITS = 30
DEFAULT_OUTPUT_TOKENS = 1024
DEFAULT_TIMEOUT_SECONDS = 120
DEFAULT_CONCURRENCY = 4
MAX_CONCURRENCY = 8
DEFAULT_ATTEMPTS = 1
MAX_ATTEMPTS = 3
DEFAULT_DEADLINE_MINUTES = 0
MAX_DEADLINE_MINUTES = 360
SENSITIVE_ASSIGNMENT = re.compile(
    r'(?im)(["\']?(?:authorization|token|password|secret|client[_-]?secret|'
    r'(?:x-)?api[_-]?key)["\']?\s*[:=]\s*)'
    r'(?:"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    r"|(?:(?:bearer|basic|token)\s+)?[^\"'\s,}\]]+)"
)


class EvalError(RuntimeError):
    """Represent an invalid eval configuration or failed SDK run."""


@dataclass(frozen=True, slots=True)
class EvalCase:
    """Store one validated reliability prompt."""

    case_id: str
    skill_name: str
    prompt: str
    expected_output: str
    assertions: tuple[str, ...]


@dataclass(frozen=True, slots=True)
class RunLimits:
    """Store bounded SDK session settings."""

    ai_credits: int
    output_tokens: int
    timeout_seconds: int

    def validate(self) -> None:
        """Reject unsafe or unsupported limit values."""

        if not 30 <= self.ai_credits <= 100:
            raise EvalError("max AI credits must be between 30 and 100")
        if not 128 <= self.output_tokens <= 2048:
            raise EvalError("max output tokens must be between 128 and 2048")
        if not 30 <= self.timeout_seconds <= 300:
            raise EvalError("session timeout must be between 30 and 300 seconds")


@dataclass(frozen=True, slots=True)
class EvalRequest:
    """Store the inputs for one with-skill and baseline comparison."""

    case: EvalCase
    content_root: Path
    output_dir: Path
    model: str
    limits: RunLimits


@dataclass(frozen=True, slots=True)
class RecordedSessionError:
    """Store an exception raised outside the SDK event stream."""

    error_type: str
    message: str
    error_code: str | None


class EvalCatalog:
    """Load and validate the consolidated SDAF reliability corpus."""

    def __init__(self, content_root: Path) -> None:
        """Load cases from ``evals/evals.json`` below the content root."""

        self.content_root = content_root.resolve()
        self.skill_names = self._load_skill_names()
        self.cases = self._load_cases()

    def case_ids(self) -> tuple[str, ...]:
        """Return all validated case IDs in stable order."""

        return tuple(sorted(self.cases))

    def get(self, case_id: str) -> EvalCase:
        """Return one validated case or raise a clear configuration error."""

        try:
            return self.cases[case_id]
        except KeyError as error:
            raise EvalError(f"unknown case: {case_id!r}") from error

    def _load_skill_names(self) -> frozenset[str]:
        """Return names backed by safe production skill documents."""

        skill_root = self.content_root / "skills"
        if not skill_root.is_dir():
            raise EvalError(f"missing skills directory: {skill_root}")
        names: set[str] = set()
        for skill_file in sorted(skill_root.glob("*/SKILL.md")):
            self._require_safe_file(skill_file, skill_root)
            names.add(skill_file.parent.name)
        if len(names) != 18:
            raise EvalError(f"expected 18 skills, found {len(names)}")
        return frozenset(names)

    def _load_cases(self) -> dict[str, EvalCase]:
        """Parse 18 skill groups and 54 unique cases."""

        eval_file = self.content_root / "evals" / "evals.json"
        self._require_safe_file(eval_file, self.content_root / "evals")
        try:
            document = json.loads(eval_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise EvalError(f"cannot read {eval_file}: {error}") from error
        groups = document.get("skills") if isinstance(document, dict) else None
        if not isinstance(groups, list) or len(groups) != 18:
            raise EvalError("evals/evals.json must contain exactly 18 skill groups")
        cases: dict[str, EvalCase] = {}
        owners: set[str] = set()
        for group in groups:
            self._load_group(group, owners, cases)
        if owners != set(self.skill_names):
            raise EvalError("eval skill groups must exactly match production skills")
        if len(cases) != 54:
            raise EvalError(f"expected 54 eval cases, found {len(cases)}")
        return cases

    def _load_group(
        self,
        group: Any,
        owners: set[str],
        cases: dict[str, EvalCase],
    ) -> None:
        """Validate one skill group and add its cases."""

        if not isinstance(group, dict) or set(group) != {"skill_name", "evals"}:
            raise EvalError("each eval skill group must contain skill_name and evals")
        owner = self._text(group["skill_name"], "skill_name")
        if owner not in self.skill_names or owner in owners:
            raise EvalError(f"invalid or duplicate eval skill group: {owner}")
        owners.add(owner)
        raw_cases = group["evals"]
        if not isinstance(raw_cases, list) or len(raw_cases) != 3:
            raise EvalError(f"{owner} must contain exactly three eval cases")
        for raw_case in raw_cases:
            case = self._parse_case(owner, raw_case)
            if case.case_id in cases:
                raise EvalError(f"duplicate eval case ID: {case.case_id}")
            cases[case.case_id] = case

    def _parse_case(self, owner: str, value: Any) -> EvalCase:
        """Validate one eval case."""

        expected_fields = {
            "id",
            "prompt",
            "expected_output",
            "assertions",
            "x-sdaf-routing",
        }
        if not isinstance(value, dict) or set(value) != expected_fields:
            raise EvalError(f"{owner} case fields do not match the reliability schema")
        case_id = self._text(value["id"], f"{owner}.id")
        if not CASE_ID_PATTERN.fullmatch(case_id):
            raise EvalError(f"invalid case ID: {case_id}")
        routing = value["x-sdaf-routing"]
        if routing != {"expected_skill": owner}:
            raise EvalError(f"{case_id} expected_skill must be {owner}")
        assertions = value["assertions"]
        if (
            not isinstance(assertions, list)
            or len(assertions) != ASSERTION_COUNT
            or not all(isinstance(item, str) and item.strip() for item in assertions)
        ):
            raise EvalError(f"{case_id} must contain five non-empty assertions")
        return EvalCase(
            case_id=case_id,
            skill_name=owner,
            prompt=self._text(value["prompt"], f"{case_id}.prompt"),
            expected_output=self._text(
                value["expected_output"],
                f"{case_id}.expected_output",
            ),
            assertions=tuple(assertions),
        )

    @staticmethod
    def _text(value: Any, location: str) -> str:
        """Return one required non-empty string."""

        if not isinstance(value, str) or not value.strip():
            raise EvalError(f"{location} must be a non-empty string")
        return value

    @staticmethod
    def _require_safe_file(path: Path, root: Path) -> None:
        """Reject missing files, links, hardlinks, and root escapes."""

        try:
            info = path.lstat()
        except OSError as error:
            raise EvalError(f"cannot inspect {path}: {error}") from error
        if path.is_symlink() or info.st_nlink != 1 or not path.is_file():
            raise EvalError(f"unsafe eval input file: {path}")
        try:
            path.resolve().relative_to(root.resolve())
        except ValueError as error:
            raise EvalError(f"eval input escapes its root: {path}") from error


class SessionEvidence:
    """Collect official typed Copilot SDK events for one session."""

    def __init__(self) -> None:
        """Initialize empty evidence and an idle completion signal."""

        self.loaded_skills: tuple[SkillsLoadedSkill, ...] = ()
        self.invocations: list[SkillInvokedData] = []
        self.messages: list[AssistantMessageData] = []
        self.usage: list[AssistantUsageData] = []
        self.errors: list[SessionErrorData | RecordedSessionError] = []
        self.idle: SessionIdleData | None = None
        self._done = asyncio.Event()

    def handle(self, event: SessionEvent) -> None:
        """Collect one event using the SDK's event discriminator and types."""

        if event.type == SessionEventType.SESSION_SKILLS_LOADED:
            if isinstance(event.data, SessionSkillsLoadedData):
                self.loaded_skills = tuple(event.data.skills)
        elif event.type == SessionEventType.SKILL_INVOKED:
            if isinstance(event.data, SkillInvokedData):
                self.invocations.append(event.data)
        elif event.type == SessionEventType.ASSISTANT_MESSAGE:
            if isinstance(event.data, AssistantMessageData):
                self.messages.append(event.data)
        elif event.type == SessionEventType.ASSISTANT_USAGE:
            if isinstance(event.data, AssistantUsageData):
                self.usage.append(event.data)
        elif event.type == SessionEventType.SESSION_ERROR:
            if isinstance(event.data, SessionErrorData):
                self.errors.append(event.data)
        elif event.type == SessionEventType.SESSION_IDLE:
            if isinstance(event.data, SessionIdleData):
                self.idle = event.data
                self._done.set()

    async def wait(self, timeout_seconds: int) -> None:
        """Wait until the SDK reports the session is idle."""

        await asyncio.wait_for(self._done.wait(), timeout=timeout_seconds)

    @property
    def response(self) -> str:
        """Return the last non-empty complete assistant message."""

        responses = [item.content.strip() for item in self.messages if item.content.strip()]
        return responses[-1] if responses else ""

    @property
    def successful(self) -> bool:
        """Return whether the session reached idle without an error."""

        return self.idle is not None and not self.idle.aborted and not self.errors


class SdafSkillEvals:
    """Run one case with the target enabled and disabled."""

    def __init__(self, request: EvalRequest) -> None:
        """Initialize one case evaluator."""

        self.request = request
        self.skills_dir = request.content_root / "skills"
        self.skill_hashes = self.source_hashes()

    async def evaluate(self) -> dict[str, Any]:
        """Run both isolated sessions and return the complete result."""

        started = datetime.now(timezone.utc)
        with_skill = await self._run_session(disable_target=False)
        baseline = await self._run_session(disable_target=True)
        unchanged = self.skill_hashes == self.source_hashes()
        grades = self._grade(with_skill, baseline, unchanged)
        result = {
            "schema_version": 1,
            "case_id": self.request.case.case_id,
            "expected_skill": self.request.case.skill_name,
            "expected_output": self.request.case.expected_output,
            "passed": all(item["passed"] for item in grades),
            "assertions": grades,
            "with_skill": self._session_summary(with_skill),
            "without_skill": self._session_summary(baseline),
            "production_hashes_unchanged": unchanged,
            "started_at": started.isoformat(),
            "ended_at": datetime.now(timezone.utc).isoformat(),
        }
        self._write_artifacts(with_skill, baseline, result)
        return result

    def source_hashes(self) -> dict[str, str]:
        """Hash all source skill files before and after sessions."""

        return {
            str(path.relative_to(self.request.content_root)): hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
            for path in sorted(self.skills_dir.glob("*/SKILL.md"))
        }

    async def _run_session(self, disable_target: bool) -> SessionEvidence:
        """Run one isolated SDK session and retain expected failures."""

        evidence = SessionEvidence()
        try:
            await self._execute_session(evidence, disable_target)
        except (OSError, RuntimeError, TimeoutError) as error:
            evidence.errors.append(
                RecordedSessionError(
                    error_type="runtime",
                    message=redact(str(error)),
                    error_code=type(error).__name__,
                )
            )
        return evidence

    async def _execute_session(
        self,
        evidence: SessionEvidence,
        disable_target: bool,
    ) -> None:
        """Execute the SDK session while collecting partial event evidence."""

        with tempfile.TemporaryDirectory(prefix="sdaf-skill-eval-") as directory:
            temp_root = Path(directory)
            home = temp_root / "copilot-home"
            workspace = temp_root / "workspace"
            home.mkdir()
            workspace.mkdir()
            async with CopilotClient(
                connection=RuntimeConnection.for_stdio(),
                working_directory=str(workspace),
                base_directory=str(home),
                env=dict(os.environ),
                log_level="error",
                mode="empty",
                session_idle_timeout_seconds=self.request.limits.timeout_seconds,
            ) as client:
                session = await client.create_session(
                    model=self.request.model,
                    working_directory=str(workspace),
                    enable_config_discovery=False,
                    enable_on_demand_instruction_discovery=False,
                    enable_file_hooks=False,
                    enable_host_git_operations=False,
                    enable_session_store=False,
                    enable_skills=True,
                    skill_directories=[str(self.skills_dir.resolve())],
                    disabled_skills=([self.request.case.skill_name] if disable_target else None),
                    available_tools=ToolSet().add_builtin("skill"),
                    session_limits={
                        "max_ai_credits": self.request.limits.ai_credits,
                    },
                    model_capabilities=ModelCapabilitiesOverride(
                        limits=ModelLimitsOverride(
                            max_output_tokens=self.request.limits.output_tokens
                        )
                    ),
                    streaming=True,
                    memory={"enabled": False},
                    on_event=evidence.handle,
                )
                async with session:
                    await session.send(self.request.case.prompt)
                    await evidence.wait(self.request.limits.timeout_seconds)

    def _documented_companions(self, target: str) -> frozenset[str]:
        """Return sibling skills the target document names as handoffs or prerequisites.

        Invoking a documented companion is designed behaviour, so it must not be
        graded as a mis-route. Any skill absent from the document still fails.
        """

        skill_file = self.skills_dir / target / "SKILL.md"
        try:
            body = skill_file.read_text(encoding="utf-8")
        except OSError as error:
            raise EvalError(f"cannot read {skill_file}: {error}") from error
        return frozenset(set(SKILL_REFERENCE_PATTERN.findall(body)) - {target})

    def _grade(
        self,
        with_skill: SessionEvidence,
        baseline: SessionEvidence,
        hashes_unchanged: bool,
    ) -> list[dict[str, Any]]:
        """Grade the five declared reliability assertions."""

        target = self.request.case.skill_name
        target_loaded = [
            item for item in with_skill.loaded_skills if item.name == target and item.enabled
        ]
        target_invocations = [item for item in with_skill.invocations if item.name == target]
        other_invocations = [
            item.name
            for item in with_skill.invocations
            if item.name.startswith("sdaf-")
            and item.name != target
            and item.name not in self._documented_companions(target)
        ]
        baseline_target = [item for item in baseline.invocations if item.name == target]
        invocation_passed = (
            len(target_loaded) == 1
            and len(target_invocations) >= 1
            and all(
                item.trigger == SkillInvokedTrigger.AGENT_INVOKED for item in target_invocations
            )
        )
        return [
            self._assertion(0, invocation_passed, self._invocation_evidence(target_invocations)),
            self._assertion(1, not other_invocations, {"other_skills": other_invocations}),
            self._assertion(2, not baseline_target, {"target_count": len(baseline_target)}),
            self._assertion(
                3,
                with_skill.successful and baseline.successful and hashes_unchanged,
                {
                    "with_skill_success": with_skill.successful,
                    "baseline_success": baseline.successful,
                    "hashes_unchanged": hashes_unchanged,
                },
            ),
            self._assertion(
                4,
                bool(with_skill.response),
                {"response_length": len(with_skill.response)},
            ),
        ]

    def _assertion(
        self,
        index: int,
        passed: bool,
        evidence: dict[str, Any],
    ) -> dict[str, Any]:
        """Render one assertion result using the case's declared text."""

        return {
            "text": self.request.case.assertions[index],
            "passed": passed,
            "evidence": evidence,
        }

    @staticmethod
    def _invocation_evidence(items: Sequence[SkillInvokedData]) -> dict[str, Any]:
        """Render minimal invocation evidence without skill content."""

        return {
            "count": len(items),
            "events": [
                {
                    "name": item.name,
                    "path": item.path,
                    "plugin_name": item.plugin_name,
                    "plugin_version": item.plugin_version,
                    "source": item.source,
                    "trigger": item.trigger.value if item.trigger else None,
                }
                for item in items
            ],
        }

    @staticmethod
    def _session_summary(evidence: SessionEvidence) -> dict[str, Any]:
        """Render safe session evidence without skill content."""

        return {
            "successful": evidence.successful,
            "loaded_skills": [
                {"name": item.name, "enabled": item.enabled, "path": item.path}
                for item in evidence.loaded_skills
            ],
            "invocations": [
                {
                    "name": item.name,
                    "path": item.path,
                    "plugin_name": item.plugin_name,
                    "trigger": item.trigger.value if item.trigger else None,
                }
                for item in evidence.invocations
            ],
            "errors": [
                {
                    "type": item.error_type,
                    "message": redact(item.message),
                    "code": item.error_code,
                }
                for item in evidence.errors
            ],
            "usage": [
                {
                    "model": item.model,
                    "input_tokens": item.input_tokens,
                    "output_tokens": item.output_tokens,
                    "cost": item.cost,
                    "duration_ms": (
                        item.duration.total_seconds() * 1000 if item.duration else None
                    ),
                }
                for item in evidence.usage
            ],
            "response_length": len(evidence.response),
        }

    def _write_artifacts(
        self,
        with_skill: SessionEvidence,
        baseline: SessionEvidence,
        result: dict[str, Any],
    ) -> None:
        """Write redacted responses, usage, grading, and summary."""

        self.request.output_dir.mkdir(parents=True, exist_ok=True)
        for name, evidence in (
            ("with_skill", with_skill),
            ("without_skill", baseline),
        ):
            arm_dir = self.request.output_dir / name
            arm_dir.mkdir()
            (arm_dir / "response.txt").write_text(
                redact(evidence.response),
                encoding="utf-8",
                newline="\n",
            )
            (arm_dir / "timing.json").write_text(
                json.dumps(self._session_summary(evidence)["usage"], indent=2) + "\n",
                encoding="utf-8",
                newline="\n",
            )
        grading = {
            "passed": result["passed"],
            "assertions": result["assertions"],
        }
        self._write_json(self.request.output_dir / "grading.json", grading)
        self._write_json(self.request.output_dir / "result.json", result)

    @staticmethod
    def _write_json(path: Path, document: dict[str, Any]) -> None:
        """Write one stable JSON artifact."""

        path.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
            newline="\n",
        )


def redact(text: str) -> str:
    """Redact simple credential assignments from response artifacts."""

    return SENSITIVE_ASSIGNMENT.sub(
        lambda match: f"{match.group(1)}[REDACTED]",
        text,
    )


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line interface."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--content-root", type=Path, default=Path.cwd())
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--list", action="store_true")
    modes.add_argument("--case")
    modes.add_argument("--all", action="store_true")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument(
        "--concurrency",
        type=int,
        default=int(os.environ.get("SDAF_EVAL_CONCURRENCY", DEFAULT_CONCURRENCY)),
    )
    parser.add_argument(
        "--attempts",
        type=int,
        default=int(os.environ.get("SDAF_EVAL_ATTEMPTS", DEFAULT_ATTEMPTS)),
    )
    parser.add_argument(
        "--deadline-minutes",
        type=int,
        default=int(os.environ.get("SDAF_EVAL_DEADLINE_MINUTES", DEFAULT_DEADLINE_MINUTES)),
    )
    parser.add_argument("--model", default="gpt-5-mini")
    parser.add_argument(
        "--max-ai-credits",
        type=int,
        default=int(os.environ.get("SDAF_EVAL_MAX_AI_CREDITS", DEFAULT_AI_CREDITS)),
    )
    parser.add_argument(
        "--max-output-tokens",
        type=int,
        default=int(os.environ.get("SDAF_EVAL_MAX_OUTPUT_TOKENS", DEFAULT_OUTPUT_TOKENS)),
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(
            os.environ.get(
                "SDAF_EVAL_SESSION_TIMEOUT_SECONDS",
                DEFAULT_TIMEOUT_SECONDS,
            )
        ),
    )
    return parser


async def run_case(args: argparse.Namespace, case: EvalCase) -> int:
    """Run one selected reliability case."""

    if args.output_dir is None:
        raise EvalError("--output-dir is required with --case")
    limits = RunLimits(args.max_ai_credits, args.max_output_tokens, args.timeout)
    limits.validate()
    request = EvalRequest(
        case=case,
        content_root=args.content_root.resolve(),
        output_dir=args.output_dir.resolve(),
        model=args.model,
        limits=limits,
    )
    result = await SdafSkillEvals(request).evaluate()
    print(json.dumps({"case_id": case.case_id, "passed": result["passed"]}))
    return 0 if result["passed"] else 1


async def run_all(args: argparse.Namespace, catalog: EvalCatalog) -> int:
    """Run every case in one process with bounded concurrency."""

    if args.output_dir is None:
        raise EvalError("--output-dir is required with --all")
    if not 1 <= args.concurrency <= MAX_CONCURRENCY:
        raise EvalError(f"concurrency must be between 1 and {MAX_CONCURRENCY}")
    if not 1 <= args.attempts <= MAX_ATTEMPTS:
        raise EvalError(f"attempts must be between 1 and {MAX_ATTEMPTS}")
    if not 0 <= args.deadline_minutes <= MAX_DEADLINE_MINUTES:
        raise EvalError(f"deadline must be between 0 and {MAX_DEADLINE_MINUTES} minutes")
    limits = RunLimits(args.max_ai_credits, args.max_output_tokens, args.timeout)
    limits.validate()
    content_root = args.content_root.resolve()
    output_dir = args.output_dir.resolve()
    gate = asyncio.Semaphore(args.concurrency)

    async def run_one(case_id: str) -> dict[str, Any]:
        case_dir = output_dir / case_id
        summary: dict[str, Any] = {"case_id": case_id, "passed": False}
        async with gate:
            for attempt in range(1, args.attempts + 1):
                request = EvalRequest(
                    case=catalog.get(case_id),
                    content_root=content_root,
                    output_dir=case_dir / f"attempt-{attempt}",
                    model=args.model,
                    limits=limits,
                )
                try:
                    result = await SdafSkillEvals(request).evaluate()
                    summary = {
                        "case_id": case_id,
                        "passed": bool(result["passed"]),
                        "attempts": attempt,
                    }
                except (EvalError, OSError, RuntimeError, TypeError, ValueError) as error:
                    summary = {
                        "case_id": case_id,
                        "passed": False,
                        "attempts": attempt,
                        "error": redact(f"{type(error).__name__}: {error}"),
                    }
                if summary["passed"]:
                    break
        print(json.dumps(summary), flush=True)
        return summary

    case_ids = catalog.case_ids()
    tasks = {asyncio.create_task(run_one(case_id)): case_id for case_id in case_ids}
    deadline = args.deadline_minutes * 60 if args.deadline_minutes else None
    done, pending = await asyncio.wait(tasks, timeout=deadline)
    for task in pending:
        task.cancel()
    if pending:
        await asyncio.gather(*pending, return_exceptions=True)
    summaries = [task.result() for task in done]
    summaries.extend(
        {
            "case_id": tasks[task],
            "passed": False,
            "error": f"DeadlineExceeded: batch exceeded {args.deadline_minutes} minutes",
        }
        for task in pending
    )
    return report_batch(summaries, output_dir)


def report_batch(summaries: list[dict[str, Any]], output_dir: Path) -> int:
    """Write the batch summary artifact and job report, then return an exit code."""

    failures = [item for item in summaries if not item["passed"]]
    document = {
        "schema_version": 1,
        "total": len(summaries),
        "passed": len(summaries) - len(failures),
        "failed": len(failures),
        "cases": sorted(summaries, key=lambda item: item["case_id"]),
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "summary.json").write_text(
        json.dumps(document, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    lines = [
        "## Skill routing reliability",
        "",
        f"{document['passed']} of {document['total']} cases passed.",
        "",
        f"{sum(1 for item in summaries if item.get('attempts', 1) > 1)} case(s) needed a retry.",
        "",
        "| Case | Result | Attempts |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| {item['case_id']} | {'pass' if item['passed'] else 'FAIL'} "
        f"| {item.get('attempts', 1)} |"
        for item in document["cases"]
    )
    report = "\n".join(lines) + "\n"
    print(report)
    step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if step_summary:
        with open(step_summary, "a", encoding="utf-8") as handle:
            handle.write(report)
    for item in failures:
        print(f"failed: {item['case_id']} {item.get('error', '')}".rstrip(), file=sys.stderr)
    return 1 if failures else 0


def main(argv: Sequence[str] | None = None) -> int:
    """List cases or run SDK-backed reliability comparisons."""

    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        catalog = EvalCatalog(args.content_root)
        if args.list:
            for case_id in catalog.case_ids():
                print(case_id)
            return 0
        if args.all:
            return asyncio.run(run_all(args, catalog))
        case = catalog.get(args.case or "")
        return asyncio.run(run_case(args, case))
    except (EvalError, OSError, RuntimeError, TypeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
