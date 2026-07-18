---
sidebar_position: 2
title: Engineering case studies
---

# Engineering case studies

## Storage failure presented as a network failure

**Signal.** Several virtual machines became unreachable at the same time, which
initially resembled an SSH ban or firewall regression.

**Investigation.** Correlating guest-agent failures with blocked hypervisor
tasks exposed a shared NFS dependency. The network symptoms were downstream of
storage I/O waits.

**Response.** The diagnostic runbook now checks NAS and VM storage before
changing firewall state. Shutdown handling was hardened and the architectural
constraint—service disks sharing a temporary storage fault domain—is explicit.

**Lesson.** Correlation across layers beats repeated probes at the layer showing
the symptom.

## Docker publishing bypassed the intended trust boundary

**Signal.** Services bound to host ports could be reached outside the reverse
proxy path even when the host firewall policy appeared restrictive.

**Investigation.** Docker&apos;s forwarding rules were evaluated before the expected
host input path.

**Response.** A persistent, inventory-driven `DOCKER-USER` policy now restricts
published ports to approved proxy and administration sources. Direct Docker
socket consumers were removed or placed behind a filtered socket proxy.

**Lesson.** A control is only real when tested on the packet path actually used.

## Vulnerability scanner growth exhausted its system disk

**Signal.** The vulnerability platform stayed operational, but its nightly
database backup began failing with `No space left on device`.

**Investigation.** Image cleanup offered no useful reclaim: the space was mostly
active feed and database data. Backup history added several gigabytes more.

**Response.** The virtual disk and filesystem were expanded online. Daily
integrity checks now alert on stale or truncated archives, while capacity is
treated as a growth metric rather than a one-off cleanup target.

**Lesson.** For data-heavy security tooling, retention and backup capacity must
be designed together.

## Secret handling evolved without breaking access

**Signal.** A privileged web administration token was still represented as a
reusable plaintext value in runtime configuration.

**Response.** It was converted in place to a memory-hard password hash while
preserving operator access. Public registration was disabled and invitations
remain available for controlled onboarding.

**Next control.** SOPS with an Age recipient is prepared for encrypted secret
delivery. The private recovery key remains outside Git and requires independent
backup.
