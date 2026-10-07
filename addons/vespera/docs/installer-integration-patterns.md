# Installer Integration Patterns (Developer Note)

This note explains why opkg-manager avoids using `patch` against shared system/UI files during package install and remove.

For the small number of UI touchpoints that still need file-level integration, opkg-manager uses a custom script: `src/data/opkg-manager/file-patcher`.

## Why this matters

Installers run on many firmware versions and combinations of add-ons. Shared-file patching is fragile in that environment because each package does not fully control the final file state.

## Patch workflow vs structured integration

| Topic | Patch-based workflow | Structured integration pattern |
| --- | --- | --- |
| Firmware drift | Patch can fail when target file changes upstream. | Integration reads/writes owned config/data surfaces that remain stable across versions. |
| Multi-package behavior | Two packages patching the same file can conflict by order of install/remove. | Each package owns its own entries/files, reducing cross-package coupling. |
| Uninstall and rollback | Hard to restore exact prior state after multiple overlapping patches. | Package can remove only artifacts it owns, making rollback predictable. |
| Observability | Failures often appear as partial hunks or silent offsets. | Behavior is explicit in package-managed files and helper logic. |
| Upgrade safety | Reapplying old patches after firmware upgrade is risky. | Reconciliation logic can rebuild state from package metadata/settings. |

## Preferred patterns in opkg-manager

- Use package-owned files, generated fragments, or registries instead of editing shared base files directly.
- When a shared QML file must be touched, limit changes to very small hook blocks near the end of the file.
- Apply/remove those hook blocks with `file-patcher apply` and `file-patcher revert` so the operation is symmetric.
- Model integration through settings/metadata and helper scripts that can be re-applied safely.
- Keep ownership clear: install creates package-owned artifacts, uninstall removes only those artifacts.
- Design for idempotency: running install/remove multiple times, in different orders, should converge to the same result.

## Practical rule of thumb

If a change requires editing a shared file that other packages or firmware also modify, treat that as a design smell. Prefer an integration seam where package ownership and cleanup are explicit.
