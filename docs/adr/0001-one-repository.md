# ADR 0001: One repository with MATLAB namespaces and versioned reproductions

Status: proposed reference convention, implemented by the starter package.

Use one repository now because common Bellman/data/execution changes need synchronized review across a single researcher's methods. Separate papers by configuration and local method extensions. Use functions and explicit structs before introducing object hierarchies.

Revisit splitting when a component has independent maintainers, incompatible dependencies, or a real release cycle. Do not split solely because there are many algorithm names.

Upstream research scripts remain provenance records and isolated baselines; they are not added wholesale to the MATLAB path or redistributed by this starter.
