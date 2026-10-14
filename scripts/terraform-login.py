#!/usr/bin/env python3
"""Run Terraform with temporary AWS console-login credentials in its child environment."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def locate_tool(explicit, name, candidates):
    if explicit:
        resolved = shutil.which(explicit)
        if resolved:
            return resolved
        path = Path(explicit).expanduser()
        if path.is_file():
            return str(path.resolve())
        raise ValueError(f"Cannot find {name}; check its explicit path.")
    resolved = shutil.which(name)
    if resolved:
        return resolved
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)
    raise ValueError(f"Cannot find {name}; supply --{name} with its executable path.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default="scaler-lab", help="AWS login profile (default: scaler-lab)")
    parser.add_argument("--region", default="ap-south-1", help="AWS resource Region")
    parser.add_argument("--aws", help="AWS CLI executable; otherwise discover its installation")
    parser.add_argument("--terraform", help="Terraform executable; otherwise use PATH or the lab tools directory")
    parser.add_argument("terraform_args", nargs=argparse.REMAINDER, help="Terraform arguments after --")
    args = parser.parse_args(argv)
    terraform_args = args.terraform_args
    if terraform_args[:1] == ["--"]:
        terraform_args = terraform_args[1:]
    if not terraform_args:
        parser.error("Supply a Terraform command after --, for example -- plan")

    local_app_data = Path(os.environ.get("LOCALAPPDATA", str(Path.home() / "AppData/Local")))
    program_files = Path(os.environ.get("ProgramFiles", "C:/Program Files"))
    temp_dir = Path(tempfile.gettempdir())
    try:
        aws = locate_tool(args.aws, "aws", [
            local_app_data / "Programs/Amazon/AWSCLIV2/aws.exe",
            program_files / "Amazon/AWSCLIV2/aws.exe",
        ])
        terraform = locate_tool(args.terraform, "terraform", [
            temp_dir / "scaler-devops-tools/terraform.exe",
            temp_dir / "devops-tools/terraform.exe",
        ])
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 2

    # The export command's stdout contains credentials. Capture it privately:
    # never forward stdout/stderr, write it to disk, or put it in child arguments.
    auth_env = os.environ.copy()
    for key in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_SECURITY_TOKEN"):
        auth_env.pop(key, None)
    try:
        auth = subprocess.run(
            [aws, "configure", "export-credentials", "--profile", args.profile, "--format", "process"],
            capture_output=True, text=True, env=auth_env, check=False,
        )
    except OSError:
        print("Could not start the AWS CLI. Check --aws and the installation.", file=sys.stderr)
        return 2
    if auth.returncode != 0:
        print(
            f"AWS credential export failed (exit {auth.returncode}). "
            "Refresh the selected profile with aws login, then retry. "
            "Credential-command output is intentionally not displayed.",
            file=sys.stderr,
        )
        return 1
    try:
        credentials = json.loads(auth.stdout)
        required = ("AccessKeyId", "SecretAccessKey", "SessionToken")
        if not isinstance(credentials, dict) or not all(
            isinstance(credentials.get(key), str) and credentials[key] for key in required
        ):
            raise ValueError("Missing temporary credentials")
    except (ValueError, TypeError):
        print("AWS CLI did not return valid temporary credentials; sign in again.", file=sys.stderr)
        return 1

    child_env = os.environ.copy()
    for key in ("AWS_PROFILE", "AWS_DEFAULT_PROFILE", "AWS_SECURITY_TOKEN"):
        child_env.pop(key, None)
    child_env.update({
        "AWS_ACCESS_KEY_ID": credentials["AccessKeyId"],
        "AWS_SECRET_ACCESS_KEY": credentials["SecretAccessKey"],
        "AWS_SESSION_TOKEN": credentials["SessionToken"],
        "AWS_REGION": args.region,
        "AWS_DEFAULT_REGION": args.region,
    })
    # No shell interpolation and no automatic apply approval. Terraform keeps
    # normal terminal input/output; its exit code is returned unchanged.
    try:
        return subprocess.run([terraform, *terraform_args], env=child_env, check=False).returncode
    except OSError:
        print("Could not start Terraform. Check --terraform and its installation.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
