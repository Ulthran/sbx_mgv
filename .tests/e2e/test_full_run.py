import csv
import os
import pytest
import shutil
import subprocess as sp
import tempfile


@pytest.fixture
def setup():
    temp_dir = tempfile.mkdtemp()

    reads_fp = os.path.abspath(".tests/data/reads/")

    project_dir = os.path.join(temp_dir, "project/")

    sp.check_output(["sunbeam", "init", "--data_fp", reads_fp, project_dir])

    yield temp_dir, project_dir

    shutil.rmtree(temp_dir)


@pytest.fixture
def run_sunbeam(setup):
    temp_dir, project_dir = setup

    # Run the test job.
    sp.check_output(
        [
            "sunbeam",
            "run",
            "--profile",
            project_dir,
            "all_mgv",
            "--directory",
            temp_dir,
        ]
    )

    output_fp = os.path.join(project_dir, "sunbeam_output")

    long_fp = os.path.join(output_fp, f"virus/mgv/LONG_out/LONG.tsv")
    short_fp = os.path.join(output_fp, f"virus/mgv/SHORT_out/SHORT.tsv")

    benchmarks_fp = os.path.join(project_dir, "stats/")

    yield long_fp, short_fp, benchmarks_fp


def test_full_run(run_sunbeam):
    long_fp, short_fp, benchmarks_fp = run_sunbeam

    # Check output
    assert os.path.exists(long_fp)
    assert os.path.exists(short_fp)

    with open(long_fp) as f:
        assert len(f.readlines()) > 2

    assert os.stat(short_fp).st_size == 0
