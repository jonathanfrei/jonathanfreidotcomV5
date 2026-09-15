---
title: "The Computer Writing This Post Is in the Cloud"
date: 2026-09-14 23:12:51 -0400
tags: [ai, development, vps, herdr, ssh, oracle-cloud]
categories: [technology]
description: "How I turned an Oracle Cloud VPS into the primary machine for agentic development, with Herdr as a thin client over SSH."
---
This post was drafted on a computer in Oracle’s cloud. The file, Git repository, coding agent, and terminal session all live there. The computer in front of me is just a way to see and direct the work.

The server is not especially exotic. It is an Oracle Cloud Ampere A1 virtual machine running Ubuntu 24.04. It has four Arm cores, 24 GB of memory, 16 GB of swap, and a 200 GB-class disk. [Oracle Cloud’s Free Tier](https://docs.oracle.com/iaas/Content/FreeTier/freetier.htm) makes its Arm instances a good way to experiment with this setup before deciding whether it deserves a monthly bill.

That is more machine than most coding agents need. Codex and similar tools call models hosted elsewhere, so the VPS is not doing model inference. It is running the surrounding work: reading repositories, editing files, compiling code, running tests, hosting development servers, and keeping terminals alive.

This is where the appeal of a VPS became clear to me. Agentic development does not particularly need the machine under my hands. It needs a machine that stays put.

## One canonical machine

The Oracle VPS is now the primary development environment. It holds the repositories, language runtimes, dependencies, credentials, Codex, and [Herdr](https://herdr.dev/). The client needs an SSH key, an SSH configuration, and a Herdr installation. A browser or graphical editor can still be useful, but there is no need to maintain another working copy of every repository.

This avoids the awkwardness of synchronizing two computers and wondering which uncommitted change is current. SSH carries input and screen updates. Git still moves code between durable environments. If I disconnect and return from another device, the filesystem is exactly where I left it.

The arrangement is close to the old terminal-and-mainframe model, except the mainframe is a small Linux VM and the terminal can be almost any computer with a good screen and keyboard.

## Starting with Oracle’s free Arm machine

Oracle’s Ampere A1 shape is unusually well suited to this experiment. The machine running this site’s content repository has four Neoverse-N1 CPUs and 24 GB of RAM. The root filesystem is about 193 GB after formatting, with roughly 167 GB free as I write this.

That is enough room for several repositories, build artifacts, language servers, and more than one agent. Memory has also been comfortable: the server currently has plenty available even with Codex and the normal background services running. The 16 GB swap file is there as a cushion, not a substitute for RAM.

Arm is the one meaningful tradeoff. Most of the tools I use here publish Linux `aarch64` builds or install through language package managers, and Herdr supports Arm on Linux. Some proprietary binaries, browser tooling, or older dependencies still assume x86-64. I would check the important toolchain before moving an existing project. Rebuilding dependencies on the server is safer than copying `node_modules`, virtual environments, or compiled artifacts from another architecture.

Oracle’s Free Tier rules and available capacity can vary by account and region. Oracle’s current documentation distinguishes promotional credits, Always Free resources, and account-specific limits, so I would verify the shape is marked eligible in the console rather than relying on an old tutorial. Free instances also have no service-level agreement or full Oracle support. This is a good place to begin, not a reason to forget backups.

## Making SSH the foundation

Herdr’s remote features sit on top of ordinary SSH, so I wanted SSH to work cleanly before adding anything else. The server uses a normal non-root account with `sudo`. Authentication uses a key, and a short entry in the client’s `~/.ssh/config` turns the destination into a stable name:

```sshconfig
Host workbox
    HostName <server-name-or-private-address>
    User ubuntu
    IdentityFile ~/.ssh/workbox_ed25519
    IdentitiesOnly yes
```

The real test is deliberately unimpressive:

```bash
ssh workbox
```

If that fails, Herdr is not the problem. The failure belongs to the route, hostname, SSH daemon, or key.

This VPS also runs Tailscale, which gives my devices a private route to one another. I prefer normal OpenSSH over that route rather than exposing development services publicly. When setting up a similar machine, I would keep the original SSH session open until a second terminal has connected successfully over Tailscale. I would also test Oracle’s browser console as a recovery path before removing any public SSH rule. Locking the front door is less impressive when the key is still inside.

Tailscale server nodes need a little maintenance of their own. Their keys should not be allowed to expire unexpectedly; a tagged server or a deliberately managed expiry policy avoids discovering six months later that the private route disappeared. The provider console remains useful when DNS, SSH, Tailscale, or an enthusiastic firewall change goes wrong.

## Building the environment

The base system is Ubuntu 24.04 LTS. I installed the ordinary tools first: Git, `curl`, `unzip`, `jq`, `ripgrep`, build essentials, Python with virtual environments, and the runtimes required by each repository. User-installed binaries live in `~/.local/bin`, which needs to be present on the login shell’s `PATH`, not only in an interactive shell configuration.

Codex is installed directly on the VPS. Its authentication and credentials live there because that is where it runs. I prefer supported authentication flows and narrow credentials to copying a mysterious configuration directory from another computer.

Repositories have a predictable home under `~/Projects`. A new one is just a normal clone:

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone git@github.com:example/project.git
```

Moving an existing dirty workspace deserves more care. I would stop editing the source, run an `rsync` dry run, preserve the Git directory and uncommitted files, exclude generated dependencies, and rebuild them for Linux Arm. The VPS copy becomes canonical only after the repository has been inspected and its tests pass.

## Herdr over SSH

Herdr is the piece that makes the remote server pleasant to use as an agent machine. Like `tmux`, it has a background server that owns real terminal processes. Closing the client or losing the SSH connection does not end the panes. Unlike a general terminal multiplexer, [Herdr recognizes common coding agents](https://herdr.dev/docs/agents/) and shows whether each one is working, blocked, done, or idle.

This VPS is running Herdr 0.9.0 from `~/.local/bin`. Herdr can be installed on Linux or macOS with its [current installer](https://herdr.dev/docs/install/):

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

After Herdr is installed on the client and `ssh workbox` succeeds, the VPS can be saved as a machine:

```bash
herdr machine add workbox --label "Oracle VPS"
herdr
```

The setup command checks the remote Herdr installation and server and asks before changing anything. The VPS then appears in the local Herdr interface with its own workspaces, tabs, panes, and agents. The remote server still owns the processes; the local Herdr client brings back their views.

A direct connection is also available:

```bash
herdr --remote workbox
```

I use the VPS panes for agents, test output, development servers, and ordinary shells. Herdr’s sidebar is more useful as the number of agents grows because I can see which one needs an answer without opening every terminal to check.

The account on this server has systemd lingering enabled. That lets user services continue without an active login session, which is useful for an always-on development box. Herdr itself keeps terminal processes alive across client disconnections. A reboot is different: processes die when the server restarts, although Herdr can restore layouts and some supported agent sessions. Anything that truly must survive independently belongs in a `systemd` service rather than a terminal pane.

## Reaching development servers

I keep development servers bound to `127.0.0.1` instead of opening temporary ports to the internet. An SSH tunnel is enough for a quick browser session:

```bash
ssh -N -L 3000:127.0.0.1:3000 workbox
```

Port 3000 on the client now reaches port 3000 on the VPS. An editor’s port forwarding or a private Tailscale Serve route can provide the same basic result when it is more convenient.

Backups matter more once the VPS becomes canonical. Git remotes protect committed code, but not databases, uncommitted work, local configuration, or agent state. Provider snapshots are useful, though they may disappear with the instance. Anything irreplaceable should also have an off-provider backup that has survived an actual restore test.

## The machine stays put

The daily routine is now quite simple. The client connects to the private network, Herdr opens, and the Oracle VPS is waiting with its terminals and agents where they were left. The computer doing the work did not go to sleep, change networks, or come along for the trip.

There are tradeoffs. The network becomes part of the development environment. The server needs updates, backups, and a recovery path. Some Arm compatibility problems are real. Renting a VPS also means trusting the hosting provider with the machine beneath the filesystem.

But the experiment does not require expensive hardware. The computer writing this post is a free-tier Arm VM. It stays in one place, does the work, and lets almost any other computer become its screen. SSH connects the two, and Herdr makes the distance mostly disappear.
