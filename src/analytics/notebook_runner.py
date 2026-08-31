"""Minimal top-to-bottom notebook execution using the installed Jupyter kernel."""

from __future__ import annotations

from pathlib import Path
import time

from jupyter_client import KernelManager
import nbformat
from nbformat.v4 import new_output

from .db import PROJECT_ROOT


def execute_notebook(path: str | Path, timeout_seconds: int = 1_800) -> float:
    """Execute code cells in order, persist outputs, and return elapsed seconds."""
    notebook_path = Path(path).resolve()
    notebook = nbformat.read(notebook_path, as_version=4)
    manager = KernelManager(kernel_name="python3")
    manager.start_kernel(cwd=str(PROJECT_ROOT))
    client = manager.client()
    client.start_channels()
    started = time.perf_counter()
    try:
        client.wait_for_ready(timeout=60)
        execution_count = 0
        for cell in notebook.cells:
            if cell.cell_type != "code":
                continue
            execution_count += 1
            cell.execution_count = execution_count
            cell.outputs = []
            message_id = client.execute(cell.source, store_history=True, stop_on_error=True)
            cell_started = time.perf_counter()
            while True:
                remaining = timeout_seconds - (time.perf_counter() - cell_started)
                if remaining <= 0:
                    raise TimeoutError(f"Notebook cell {execution_count} exceeded {timeout_seconds}s")
                message = client.get_iopub_msg(timeout=min(30, max(1, remaining)))
                if message["parent_header"].get("msg_id") != message_id:
                    continue
                message_type = message["msg_type"]
                content = message["content"]
                if message_type == "status" and content.get("execution_state") == "idle":
                    break
                if message_type == "stream":
                    cell.outputs.append(new_output("stream", name=content["name"], text=content["text"]))
                elif message_type in {"display_data", "execute_result"}:
                    output_fields = {
                        "data": content.get("data", {}),
                        "metadata": content.get("metadata", {}),
                    }
                    if message_type == "execute_result":
                        output_fields["execution_count"] = content.get("execution_count")
                    cell.outputs.append(new_output(message_type, **output_fields))
                elif message_type == "error":
                    cell.outputs.append(
                        new_output(
                            "error",
                            ename=content.get("ename", "Error"),
                            evalue=content.get("evalue", ""),
                            traceback=content.get("traceback", []),
                        )
                    )
                    raise RuntimeError(
                        f"Notebook cell {execution_count} failed: "
                        f"{content.get('ename')}: {content.get('evalue')}"
                    )
        elapsed = time.perf_counter() - started
        notebook.metadata["hospital360_execution"] = {
            "status": "PASS",
            "runtime_seconds": round(elapsed, 3),
            "runner": "src.analytics.notebook_runner",
        }
        nbformat.write(notebook, notebook_path)
        return elapsed
    finally:
        client.stop_channels()
        manager.shutdown_kernel(now=True)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("notebook")
    parser.add_argument("--timeout", type=int, default=1_800)
    args = parser.parse_args()
    duration = execute_notebook(args.notebook, args.timeout)
    print(f"Notebook execution PASS in {duration:.3f} seconds")
