import argparse
import os
import subprocess
from pathlib import Path

from mlc_llm.support import logging

logging.enable_logging()
logger = logging.getLogger(__name__)


def main(apk_path: Path, package_output_path: Path):
    """Push weights to the android device with adb"""
    # - Install the apk on device.
    logger.info('Install apk "%s" to device', str(apk_path.absolute()))
    subprocess.run(["adb", "install", str(apk_path)], check=True, env=os.environ)
    # - Create the weight directory for the app.
    device_weihgt_dir = "/storage/emulated/0/Android/data/ai.mlc.mlcengineexample/files/"
    logger.info('Creating directory "%s" on device', device_weihgt_dir)
    subprocess.run(
        ["adb", "shell", "mkdir", "-p", device_weihgt_dir],
        check=True,
        env=os.environ,
    )
    for model_weight_dir in (package_output_path / "bundle").iterdir():
        if model_weight_dir.is_dir():
            src_dir = model_weight_dir.absolute()
            dst_dir = "/data/local/tmp/" + model_weight_dir.name

            for file_path in src_dir.iterdir():
                if file_path.is_file():  # Ignore directories
                    dst_path = dst_dir + "/" + file_path.name
                    logger.info('Pushing file "%s" to "%s"', file_path, dst_path)
                    subprocess.run(["adb", "push", str(file_path), dst_path], check=True, env=os.environ)
            
            dst_path = dst_dir
            src_path = dst_path
            dst_path = "/storage/emulated/0/Android/data/ai.mlc.mlcengineexample/files/" + model_weight_dir.name
            logger.info('Move weights from "%s" to "%s"', src_path, dst_path)
            subprocess.run(["adb", "shell", "mv", src_path, dst_path], check=True, env=os.environ)
    logger.info("All finished.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser("MLC LLM Android Weight Bundle")

    def _parse_apk_path(path: str) -> Path:
        path = Path(path)
        if not path.exists():
            raise ValueError(
                f"Path {str(path)} is expected to be an apk file, but the file does not exist."
            )
        if not path.is_file():
            raise ValueError(f"Path {str(path)} is expected to be an apk file.")
        return path

    parser.add_argument(
        "--apk-path",
        type=_parse_apk_path,
        default="app/release/app-release.apk",
        help="The path to generated MLCEngineExample apk file.",
    )
    parser.add_argument(
        "--package-output-path",
        type=Path,
        default="dist",
        help='The path to the output directory of "mlc_llm package".',
    )
    args = parser.parse_args()
    main(args.apk_path, args.package_output_path)