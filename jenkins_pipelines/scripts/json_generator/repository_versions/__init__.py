from .v43_nodes import get_v43_nodes_sorted
from .v50_nodes import get_v50_nodes_sorted
from .v51_slmicro61_nodes import get_v51_static_and_client_tools as get_v51_slmicro61_tools
from .v51_sles15sp7_nodes import get_v51_static_and_client_tools as get_v51_sles15sp7_tools

# Now you can call them explicitly
static_51_slmicro61, dynamic_51_slmicro61 = get_v51_slmicro61_tools()
static_51_sles15sp7, dynamic_51_sles15sp7 = get_v51_sles15sp7_tools()

nodes_by_version: dict[str, dict[str, dict[str, list[str]]]] = {
    "43": {"dynamic": get_v43_nodes_sorted()},
    "50": {"dynamic": get_v50_nodes_sorted(get_v43_nodes_sorted())},
    "51_slmicro61": {"static": static_51_slmicro61, "dynamic": dynamic_51_slmicro61 },
    "51_sles15sp7": {"static": static_51_sles15sp7, "dynamic": dynamic_51_sles15sp7},
}
