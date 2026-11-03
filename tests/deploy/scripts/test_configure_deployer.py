import os
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[3]
SCRIPTS = [
    ROOT / "deploy/scripts/configure_deployer.sh",
    ROOT
    / "deploy/terraform/terraform-units/modules/sap_deployer/templates/configure_deployer.sh.tmpl",
]
GIT_BASH = Path(os.environ.get("ProgramFiles", "")) / "Git/bin/bash.exe"
BASH = str(GIT_BASH) if GIT_BASH.is_file() else shutil.which("bash")


@pytest.mark.parametrize("script", SCRIPTS, ids=["standalone", "template"])
@pytest.mark.parametrize(
    "release,version,interpreter,packages",
    [
        ("8.10", "2.11", "python3", {"python36", "python3-pip"}),
        ("9.6", "2.16", "python3.11", {"python3.11", "python3.11-pip", "python3-pip"}),
        ("10.0", "2.16", "python3", {"python3-pip"}),
    ],
)
def test_rhel_packages_and_ansible_interpreter(script, release, version, interpreter, packages):
    assert BASH, "Bash is required to test deployer provisioning"
    text = script.read_text().replace("$${", "${")
    package_block = text.split("required_pkgs=(", 1)[1].split(
        "# Include distro version specific packages", 1
    )[0]
    ansible_block = text.split('echo "Set ansible version for specific distros"', 1)[1].split(
        'echo "Ansible version:', 1
    )[0]
    venv_block = (
        'case "$(get_distro_name)" in'
        + text.split("# Fail if pip3", 1)[0].rsplit('case "$(get_distro_name)" in', 1)[1]
    )
    result = subprocess.run(
        [BASH, "-s"],
        input=f"""
set -eu
get_distro_name() {{ echo rhel; }}
get_distro_version() {{ echo {release}; }}
sudo() {{ printf 'sudo:%s\\n' "$*"; }}
source() {{ :; }}
required_pkgs=({package_block}
{ansible_block}
{venv_block}
printf 'version:%s\\n' "$ansible_version"
printf 'python:%s\\n' "$ansible_python"
printf 'package:%s\\n' "${{required_pkgs[@]}}"
""",
        text=True,
        capture_output=True,
        check=True,
    )
    lines = result.stdout.splitlines()
    installed_packages = {
        line.removeprefix("package:") for line in lines if line.startswith("package:")
    }
    assert packages <= installed_packages
    assert "python311" not in installed_packages
    assert f"version:{version}" in lines
    assert f"python:{interpreter}" in lines
    assert any(line.startswith(f"sudo:{interpreter} -m venv ") for line in lines)
    if release.startswith(("9.", "10.")):
        assert "python36" not in installed_packages
        assert "python3-virtualenv" not in installed_packages
    assert not any("pip install virtualenv" in line for line in lines)
