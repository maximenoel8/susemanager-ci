import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import cache
import json
import requests
import logging
import threading

from ibs_osc_client import IbsOscClient
from repository_versions import nodes_by_version

IBS_MAINTENANCE_URL_PREFIX: str = 'http://download.suse.de/ibs/SUSE:/Maintenance:/'
JSON_OUTPUT_FILE_NAME: str = 'custom_repositories.json'

def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_cli_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="This script reads the open qam-manager requests and creates a json file that can be fed to the BV testsuite pipeline"
    )
    parser.add_argument("-v", "--version", dest="version",
                        help="Version of SUMA you want to run this script for, the options are 43 for 4.3, 50 for 5.0, and 51 for 5.1",
                        choices=["43", "50-micro", "50-sles", "51-micro","51-sles"], default="43", action='store')
    parser.add_argument("-i", "--mi_ids", required=False, dest="mi_ids", help="Space separated list of MI IDs", nargs='*', action='store')
    parser.add_argument("-f", "--file", required=False, dest="file", help="Path to a file containing MI IDs separated by newline character", action='store')
    parser.add_argument("-e", "--no_embargo", dest="embargo_check", help="Reject MIs under embargo",  action='store_true')
    return parser.parse_args()

def read_mi_ids_from_file(file_path: str) -> list[str]:
    with open(file_path, 'r') as file:
        return file.read().strip().split()

def merge_mi_ids(args: argparse.Namespace) -> set[str]:
    mi_ids: set[str] = clean_mi_ids(args.mi_ids) if args.mi_ids else set()
    if args.file:
        file_mi_ids: set[str] = set(read_mi_ids_from_file(args.file))
        mi_ids.update(file_mi_ids)

    return mi_ids

def clean_mi_ids(mi_ids: list[str]) -> set[str]:
    # support 1234,4567,8901 format
    if(len(mi_ids) == 1):
        return { id.strip() for id in mi_ids[0].split(",") }
    # support 1234, 4567, 8901 format
    return { id.replace(',', '') for id in mi_ids }

@cache
def create_url(mi_id: str, suffix: str) -> str:
    url = f"{IBS_MAINTENANCE_URL_PREFIX}{mi_id}{suffix}"

    res: requests.Response = requests.get(url, timeout=(1, 2))
    return url if res.ok else ""

def validate_and_store_results(expected_ids: set [str], custom_repositories: dict[str, dict[str, str]], output_file: str = JSON_OUTPUT_FILE_NAME):
    if not custom_repositories:
        raise SystemExit("Empty custom_repositories dictionary, something went wrong")

    found_ids: set[str] = { id for custom_repo in custom_repositories.values() for id in custom_repo.keys() }
    # there should be no set difference if all MI IDs are in the JSON
    missing_ids: set[str] = expected_ids.difference(found_ids)
    if missing_ids:
        logging.error(f"MI IDs #{missing_ids} do not exist in custom_repositories dictionary.")

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(custom_repositories, f, indent=2, sort_keys=True)

def get_version_nodes(version: str):
    version_nodes = nodes_by_version.get(version)
    if not version_nodes:
        supported_versions = ', '.join(nodes_by_version.keys())
        raise ValueError(f"No nodes for version {version} - supported versions: {supported_versions}")
    return version_nodes

def init_custom_repositories(version: str, static_repos: dict[str, dict[str, str]] = None) -> dict[str, dict[str, str]]:
    custom_repositories: dict[str, dict[str, str]] = {}
    if version.startswith("51") and static_repos:
        for node, named_urls in static_repos.items():
            custom_repositories[node] = {
                name: f"{IBS_MAINTENANCE_URL_PREFIX}{url}" if not url.startswith("http") else url
                for name, url in named_urls.items()
            }
    return custom_repositories

def update_custom_repositories(custom_repositories: dict[str, dict[str, str]], node: str, mi_id: str, url: str):
    node_ids: dict[str, str] = custom_repositories.get(node, {})
    final_id: str = mi_id
    i: int = 1
    while final_id in node_ids:
        final_id = f"{mi_id}-{i}"
        i += 1
    node_ids[final_id] = url
    custom_repositories[node] = node_ids


def find_valid_repos(mi_ids: set[str], version: str, max_workers: int = 20):
    """
    Find valid repository URLs for given MI IDs and version.

    Uses parallel HTTP requests to check repository existence.

    Args:
        mi_ids: Set of MI ID strings
        version: SUMA version (43, 50-sles, 51-sles, etc.)
        max_workers: Number of concurrent HTTP requests (default: 20)
    """
    version_data = get_version_nodes(version)

    static_repos = version_data.get("static", {})
    dynamic_nodes = version_data.get("dynamic", {})

    custom_repositories = init_custom_repositories(version, static_repos)

    # Build a list of all (node, mi_id, repo) combinations to check
    tasks = []
    for node, repositories in dynamic_nodes.items():
        for mi_id in mi_ids:
            for repo in repositories:
                tasks.append((node, mi_id, repo))

    logging.info(f"Checking {len(tasks)} repository URLs in parallel (max_workers={max_workers})")

    # Execute HTTP requests in parallel
    lock = threading.Lock()
    found_count = 0

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all tasks
        future_to_task = {
            executor.submit(create_url, mi_id, repo): (node, mi_id, repo)
            for node, mi_id, repo in tasks
        }

        # Collect results as they complete
        for future in as_completed(future_to_task):
            node, mi_id, repo = future_to_task[future]
            try:
                repo_url = future.result()
                if repo_url:
                    # Thread-safe update
                    with lock:
                        update_custom_repositories(custom_repositories, node, mi_id, repo_url)
                        found_count += 1
            except Exception as exc:
                logging.warning(f"Error checking {mi_id}{repo}: {exc}")

    logging.info(f"Found {found_count} valid repositories out of {len(tasks)} checked")
    validate_and_store_results(mi_ids, custom_repositories)

def main():
    setup_logging()
    args: argparse.Namespace = parse_cli_args()
    osc_client: IbsOscClient = IbsOscClient()

    mi_ids: set[str] = merge_mi_ids(args)
    logging.info(f"MI IDs: {mi_ids}")
    if not mi_ids:
        mi_ids = osc_client.find_maintenance_incidents()

    if args.embargo_check:
        logging.info(f"Remove MIs under embargo")
        mi_ids = { id for id in mi_ids if not osc_client.mi_is_under_embargo(id) }

    find_valid_repos(mi_ids, args.version)

if __name__ == '__main__':
    main()
