"""Tests for the 'build security' workflow (issue #139).

The workflow builds a stack image from the 'security' images of the
backend and frontend each day, and deploys it to the developer cluster.

Run with: python3 -m unittest discover -s tests
"""

import re
import unittest
from pathlib import Path

import yaml

WORKFLOW = (
    Path(__file__).resolve().parent.parent
    / ".github"
    / "workflows"
    / "build-security.yaml"
)


def _load_workflow():
    with WORKFLOW.open(encoding="utf-8") as stream:
        workflow = yaml.safe_load(stream)
    # PyYAML reads the 'on' key as the boolean True.
    if True in workflow:
        workflow["on"] = workflow.pop(True)
    return workflow


def _step(job, name):
    for step in job["steps"]:
        if step.get("name") == name:
            return step
    raise AssertionError(f"There is no step named '{name}'")


class BuildSecurityWorkflowTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.workflow = _load_workflow()
        cls.build = cls.workflow["jobs"]["build"]
        cls.deploy = cls.workflow["jobs"]["deploy-security"]

    def test_runs_on_a_daily_schedule(self):
        schedule = self.workflow["on"]["schedule"]
        self.assertEqual(len(schedule), 1)
        minute, hour, day, month, weekday = schedule[0]["cron"].split()
        self.assertTrue(minute.isdigit())
        self.assertTrue(hour.isdigit())
        self.assertEqual((day, month, weekday), ("*", "*", "*"))

    def test_can_be_started_manually(self):
        self.assertIn("workflow_dispatch", self.workflow["on"])

    def test_does_not_run_on_push(self):
        self.assertNotIn("push", self.workflow["on"])

    def test_pulls_the_backend_and_frontend_security_images(self):
        env = self.workflow["env"]
        self.assertEqual(env["BE_IMAGE_TAG"], "security")
        self.assertEqual(env["FE_IMAGE_TAG"], "security")

    def test_image_tag_is_security_and_the_date(self):
        run = _step(self.build, "Initialise workflow variables")["run"]
        self.assertIn('date -u +%Y%m%d', run)
        self.assertRegex(run, r'tag=security-\$\{?DATE\}?')

    def test_builds_both_the_dated_and_the_security_tags(self):
        build = _step(self.build, "Build")["with"]
        tags = build["tags"].splitlines()
        self.assertEqual(len(tags), 2)
        self.assertTrue(
            tags[0].endswith("/fragalysis-stack:${{ steps.vars.outputs.tag }}")
        )
        self.assertTrue(tags[1].endswith("/fragalysis-stack:security"))
        self.assertIn("BE_IMAGE_TAG=${{ env.BE_IMAGE_TAG }}", build["build-args"])
        self.assertIn("FE_IMAGE_TAG=${{ env.FE_IMAGE_TAG }}", build["build-args"])
        self.assertIn(
            "STACK_VERSION=${{ steps.vars.outputs.tag }}", build["build-args"]
        )

    def test_scans_the_image(self):
        run = _step(self.build, "Vulnerability Scan (OSV)")["run"]
        self.assertIn("osv-scanner", run)

    def test_pushes_both_tags_only_with_docker_hub_credentials(self):
        push = _step(self.build, "Push")
        self.assertEqual(push["if"], "steps.vars.outputs.push == 'true'")
        self.assertIn(":${{ steps.vars.outputs.tag }}", push["run"])
        self.assertIn(":security", push["run"])

    def test_deploys_the_dated_tag_with_the_security_awx_template(self):
        self.assertEqual(self.deploy["needs"], "build")
        self.assertEqual(self.deploy["environment"], "awx/fragalysis-security")
        condition = " ".join(self.deploy["if"].split())
        self.assertIn("needs.build.outputs.push == 'true'", condition)
        self.assertIn("needs.build.outputs.deploy == 'true'", condition)
        awx = _step(self.deploy, "Deploy security")
        self.assertTrue(
            awx["uses"].startswith("informaticsmatters/trigger-awx-action@")
        )
        self.assertEqual(awx["with"]["template"], "Security Fragalysis Stack")
        self.assertEqual(awx["with"]["template-var"], "stack_image_tag")
        self.assertEqual(
            awx["with"]["template-var-value"], "${{ needs.build.outputs.tag }}"
        )

    def test_deployment_is_controlled_by_its_own_secret(self):
        run_env = _step(self.build, "Initialise workflow variables")["env"]
        self.assertEqual(
            run_env["TRIGGER_SECURITY_AWX"], "${{ secrets.TRIGGER_SECURITY_AWX }}"
        )
        self.assertNotIn("TRIGGER_AWX", run_env)

    def test_never_deploys_to_staging_or_production(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        self.assertIsNone(re.search(r"(Staging|Production) Fragalysis Stack", text))
        self.assertNotIn("awx/fragalysis-production", text)
        self.assertNotIn("awx/fragalysis-staging", text)


if __name__ == "__main__":
    unittest.main()
