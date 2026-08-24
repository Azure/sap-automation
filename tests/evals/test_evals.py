"""Tests for the trusted SDAF skill evaluator."""

from __future__ import annotations

import asyncio
import importlib.util
import json
import os
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).parents[2]
SPEC = importlib.util.spec_from_file_location("sdaf_evals", ROOT / "evals/evals.py")
assert SPEC and SPEC.loader
EVALS = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = EVALS
SPEC.loader.exec_module(EVALS)


def make_evidence(*, target: str, response: str = "ready", failed: bool = False):
    """Create minimal session evidence for pure grading tests."""

    evidence = EVALS.SessionEvidence()
    evidence.loaded_skills = (
        SimpleNamespace(
            name=target,
            enabled=True,
            path=f"skills/{target}/SKILL.md",
        ),
    )
    evidence.invocations = [
        SimpleNamespace(
            name=target,
            trigger=EVALS.SkillInvokedTrigger.AGENT_INVOKED,
            path=f"skills/{target}/SKILL.md",
            plugin_name=None,
            plugin_version=None,
            source="custom",
        )
    ]
    evidence.messages = [SimpleNamespace(content=response)]
    evidence.idle = SimpleNamespace(aborted=False)
    if failed:
        evidence.errors = [
            SimpleNamespace(
                error_type="authentication",
                message="token=top-secret",
                error_code="401",
            )
        ]
    return evidence


@pytest.fixture(name="evaluator")
def evaluator_fixture(tmp_path: Path):
    """Create an evaluator with one hashable skill for pure unit tests."""

    skill_name = "sdaf-test-skill"
    content_root = tmp_path / "content"
    skill_dir = content_root / "skills" / skill_name
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("# Test\n", encoding="utf-8")
    case = EVALS.EvalCase(
        case_id="test-case",
        skill_name=skill_name,
        prompt="Run the test skill.",
        expected_output="The test skill loads.",
        assertions=("one", "two", "three", "four", "five"),
    )
    request = EVALS.EvalRequest(
        case=case,
        content_root=content_root,
        output_dir=tmp_path / "output",
        model="gpt-5-mini",
        limits=EVALS.RunLimits(30, 1024, 120),
    )
    return EVALS.SdafSkillEvals(request)


@pytest.fixture(name="catalog_root")
def catalog_root_fixture(tmp_path: Path) -> Path:
    """Create a complete standalone catalogue and matching skill set."""

    root = tmp_path / "catalog"
    groups = []
    for skill_index in range(18):
        skill_name = f"sdaf-test-skill-{skill_index}"
        skill_dir = root / "skills" / skill_name
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text("# Test\n", encoding="utf-8")
        cases = []
        for case_index in range(3):
            case_id = f"case-{skill_index}-{case_index}"
            cases.append(
                {
                    "id": case_id,
                    "prompt": f"Prompt {case_id}",
                    "expected_output": f"Output {case_id}",
                    "assertions": ["a", "b", "c", "d", "e"],
                    "x-sdaf-routing": {"expected_skill": skill_name},
                }
            )
        groups.append({"skill_name": skill_name, "evals": cases})
    eval_dir = root / "evals"
    eval_dir.mkdir()
    (eval_dir / "evals.json").write_text(
        json.dumps({"skills": groups}),
        encoding="utf-8",
    )
    return root


def test_catalog_loads_all_repository_cases(catalog_root: Path) -> None:
    """A complete catalogue loads all expected cases."""

    catalog = EVALS.EvalCatalog(catalog_root)

    assert len(catalog.case_ids()) == 54
    assert catalog.get("case-0-0").skill_name == "sdaf-test-skill-0"


@pytest.mark.parametrize(
    ("limits", "message"),
    [
        (EVALS.RunLimits(29, 1024, 120), "max AI credits"),
        (EVALS.RunLimits(30, 127, 120), "max output tokens"),
        (EVALS.RunLimits(30, 1024, 29), "session timeout"),
    ],
)
def test_run_limits_reject_unsafe_values(limits, message: str) -> None:
    """Each bounded runtime limit rejects values below its minimum."""

    with pytest.raises(EVALS.EvalError, match=message):
        limits.validate()


def test_catalog_rejects_unsafe_hardlinked_input(catalog_root: Path) -> None:
    """A multiply linked input cannot cross the trusted data boundary."""

    source = catalog_root / "evals" / "evals.json"
    os.link(source, source.with_name("alias.json"))

    with pytest.raises(EVALS.EvalError, match="unsafe eval input file"):
        EVALS.EvalCatalog(catalog_root)


def test_parse_case_rejects_unsafe_case_id(catalog_root: Path) -> None:
    """Artifact path identifiers must use the safe slug grammar."""

    eval_file = catalog_root / "evals" / "evals.json"
    document = json.loads(eval_file.read_text(encoding="utf-8"))
    document["skills"][0]["evals"][0]["id"] = ".."
    eval_file.write_text(json.dumps(document), encoding="utf-8")

    with pytest.raises(EVALS.EvalError, match="invalid case ID"):
        EVALS.EvalCatalog(catalog_root)


def test_grade_passes_exact_target_invocation(evaluator, monkeypatch) -> None:
    """The declared routing contract passes with one target invocation."""

    target = evaluator.request.case.skill_name
    sessions = iter(
        [
            make_evidence(target=target),
            make_evidence(target="sdaf-other-skill"),
        ]
    )

    async def fake_run_session(*, disable_target: bool):
        del disable_target
        return next(sessions)

    monkeypatch.setattr(evaluator, "_run_session", fake_run_session)

    result = asyncio.run(evaluator.evaluate())

    assert result["passed"] is True


def test_redact_masks_sensitive_assignments() -> None:
    """Response artifacts mask common credential assignments."""

    value = EVALS.redact("token=top-secret password: hunter2 safe=value")

    assert "top-secret" not in value
    assert "hunter2" not in value
    assert value.count("[REDACTED]") == 2
    assert "safe=value" in value


def test_evaluate_writes_failed_session_evidence(evaluator, monkeypatch) -> None:
    """Mocked session failures are graded and persisted without an SDK call."""

    target = evaluator.request.case.skill_name
    sessions = iter(
        [
            make_evidence(target=target, response="token=top-secret", failed=True),
            make_evidence(target="sdaf-other-skill"),
        ]
    )

    async def fake_run_session(*, disable_target: bool):
        del disable_target
        return next(sessions)

    monkeypatch.setattr(evaluator, "_run_session", fake_run_session)

    result = asyncio.run(evaluator.evaluate())

    assert result["passed"] is False
    assert (evaluator.request.output_dir / "grading.json").is_file()
    response = (evaluator.request.output_dir / "with_skill" / "response.txt").read_text(
        encoding="utf-8"
    )
    assert "top-secret" not in response


def test_cli_returns_configuration_error_for_missing_root(tmp_path: Path, capsys) -> None:
    """CLI configuration failures return the documented error status."""

    status = EVALS.main(["--content-root", str(tmp_path), "--list"])

    assert status == 2
    assert "missing skills directory" in capsys.readouterr().err
